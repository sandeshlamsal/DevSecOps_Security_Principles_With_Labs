#!/usr/bin/env python3
"""Normalise scanner JSON from run-scanners.sh into one list, tag each finding with path-based
context hints, and write summary.md + normalized.json next to the reports.

Hints are NOT verdicts. "test-fixture" means "probably noise, confirm it"; a real key in a test file
is still a real leak. The judgement (reachable? deployed? risk?) is done by the person or model triaging.

Usage: summarize.py <report-dir> [--target-root <dir>]   (target root is stripped from paths)
"""
import collections, json, os, re, sys

HINTS = [  # (tag, regex on the relative path, why it is usually lower priority)
    ("vendored",      r"(^|/)(node_modules|vendor|third_party)/", "third-party code you don't ship as your own"),
    ("test-fixture",  r"(^|/)(test|tests|__tests__|spec|fixtures?)/|\.(spec|test)\.[cm]?[jt]sx?$|_test\.(go|py)$", "test data, rarely deployed"),
    ("example-docs",  r"(^|/)(examples?|samples?|docs?|demo|codefixes)/", "examples or training snippets, usually never executed"),
    ("ci-config",     r"(^|/)\.github/", "CI definitions: in scope only if it is YOUR pipeline"),
    ("iac",           r"\.tf$|(^|/)Dockerfile[^/]*$|\.tfvars$", "infrastructure code: check whether it is deployed or served"),
]


def load(path):
    try:
        with open(path) as f:
            return json.load(f)
    except (OSError, ValueError):
        return None


def rel(p, root):
    p = p or ""
    if root and p.startswith(root):
        p = p[len(root):]
    if p.startswith("./"):
        p = p[2:]
    return p.lstrip("/")


def tag_for(path):
    for tag, rx, _ in HINTS:
        if re.search(rx, path):
            return tag
    return ""


# Only these hints mean "probably noise". "ci-config" and "iac" mean "check exposure": they can be in scope.
NOISE_HINTS = {"vendored", "test-fixture", "example-docs"}


def needs_review(i):
    """Conservative: anything not clearly noise goes to a human/model.
    Secrets are never set aside by path, except test fixtures and vendored code, and a private key never is.
    (Lesson from the eval: a Terraform private key tagged 'iac' was the audit's Critical F-013, publicly served.)"""
    if i["tool"] == "gitleaks":
        return i["rule"] == "private-key" or i["hint"] not in {"test-fixture", "vendored"}
    return i["hint"] not in NOISE_HINTS


def collect(d, root):
    out = []
    def add(tool, rule, sev, path, line, msg, extra=None):
        path = rel(path, root)
        out.append({"tool": tool, "rule": rule, "severity": (sev or "").upper(), "path": path,
                    "line": line, "message": (msg or "")[:160], "hint": tag_for(path), **(extra or {})})

    s = load(os.path.join(d, "semgrep.json"))
    for r in (s or {}).get("results", []):
        cwe = r.get("extra", {}).get("metadata", {}).get("cwe", "")
        cwe = (cwe[0] if isinstance(cwe, list) and cwe else cwe) or ""
        add("semgrep", r["check_id"].split(".")[-1], r["extra"].get("severity"), r["path"],
            r["start"]["line"], r["extra"].get("message"), {"cwe": str(cwe).split(":")[0]})

    for g in load(os.path.join(d, "gitleaks.json")) or []:
        add("gitleaks", g.get("RuleID"), "HIGH", g.get("File"), g.get("StartLine"), g.get("Description"))

    for name, tool in (("trivy-fs.json", "trivy-fs"), ("trivy-image.json", "trivy-image")):
        t = load(os.path.join(d, name))
        for res in (t or {}).get("Results", []) or []:
            for v in res.get("Vulnerabilities") or []:
                add(tool, v["VulnerabilityID"], v.get("Severity"), res.get("Target"), None,
                    f'{v.get("PkgName")} {v.get("InstalledVersion")}',
                    {"fixed": v.get("FixedVersion") or ""})

    t = load(os.path.join(d, "trivy-config.json"))
    for res in (t or {}).get("Results", []) or []:
        for m in res.get("Misconfigurations") or []:
            if m.get("Status") == "FAIL":
                add("trivy-config", m.get("ID"), m.get("Severity"), res.get("Target"), None, m.get("Title"))

    c = load(os.path.join(d, "checkov.json"))
    for block in (c if isinstance(c, list) else [c] if c else []):
        for f in (block.get("results") or {}).get("failed_checks", []):
            rng = f.get("file_line_range") or [None]
            add("checkov", f.get("check_id"), f.get("severity") or "", f.get("file_path"), rng[0], f.get("check_name"))
    return out


def main():
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    d = sys.argv[1]
    root = sys.argv[sys.argv.index("--target-root") + 1].rstrip("/") + "/" if "--target-root" in sys.argv else ""
    items = collect(d, root)

    by_tool = collections.Counter(i["tool"] for i in items)
    for i in items:
        i["needs_review"] = needs_review(i)
    by_tool_hint = collections.Counter((i["tool"], i["hint"] or "-") for i in items)
    review = [i for i in items if i["needs_review"]]
    review_by_tool = collections.Counter(i["tool"] for i in review)

    json.dump(items, open(os.path.join(d, "normalized.json"), "w"), indent=1)
    L = [f"# Triage summary: `{d}`", "", f"**{len(items)} raw results.** Hints are suggestions; confirm every set-aside.", "",
         "## Raw results by tool", "", "| Tool | Raw | Needs review |", "|---|---|---|"]
    for tool, n in sorted(by_tool.items()):
        L.append(f"| {tool} | {n} | {review_by_tool[tool]} |")
    L += ["", "## Context hints (from the path; suggestions only)", "",
          "| Tool | Hint | Count | Treated as | Why |", "|---|---|---|---|---|"]
    why = {t: w for t, _, w in HINTS}
    for (tool, hint), n in sorted(by_tool_hint.items()):
        if hint != "-":
            treated = "needs review" if (tool == "gitleaks" and hint not in {"test-fixture", "vendored"}) or hint not in NOISE_HINTS else "probable noise: confirm"
            L.append(f"| {tool} | {hint} | {n} | {treated} | {why[hint]} |")
    L += ["", "## Needs review, grouped by rule", "", "| Tool | Rule | Severity | Count | Locations (first 4) |", "|---|---|---|---|---|"]
    groups = collections.defaultdict(list)
    for i in review:
        groups[(i["tool"], i["rule"], i["severity"])].append(f'{i["path"]}' + (f':{i["line"]}' if i["line"] else ""))
    sev_rank = {"CRITICAL": 0, "ERROR": 1, "HIGH": 1, "WARNING": 2, "MEDIUM": 2, "LOW": 3, "INFO": 4}
    for (tool, rule, sev), locs in sorted(groups.items(), key=lambda kv: (sev_rank.get(kv[0][2], 5), -len(kv[1]))):
        L.append(f"| {tool} | {rule} | {sev} | {len(locs)} | {', '.join(locs[:4])} |")
    open(os.path.join(d, "summary.md"), "w").write("\n".join(L) + "\n")
    print("\n".join(L[: L.index("## Needs review, grouped by rule")]))
    print(f"\nwrote {d}/summary.md and {d}/normalized.json ({len(review)} findings need review)")


if __name__ == "__main__":
    main()
