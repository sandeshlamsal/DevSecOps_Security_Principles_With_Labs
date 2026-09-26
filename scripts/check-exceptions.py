#!/usr/bin/env python3
"""Fail if a security exception has expired, or if a scanner skip has no unexpired exception row.
Sources checked: SECURITY-EXCEPTIONS.md, `#checkov:skip=RULE:EXC-nnn ...` comments, and .trivyignore (`RULE exp:YYYY-MM-DD`)."""
import datetime, glob, re, sys

today = datetime.date.today()
rows, errors = {}, []
for line in open("SECURITY-EXCEPTIONS.md"):
    m = re.match(r"\| (EXC-\d+) \| ([^|]+) \|.*\| (\d{4}-\d{2}-\d{2}) \|[^|]*\|\s*$", line)
    if not m:
        continue
    exc, rules, expires = m.group(1), m.group(2), datetime.date.fromisoformat(m.group(3))
    rows[exc] = expires
    if expires < today:
        errors.append(f"{exc} expired on {expires}: fix the issue or renew it with a new reason")
    for r in re.findall(r"(CKV2?_[A-Z]+_\d+|KSV-\d+)", rules):
        rows.setdefault(("rule", r), exc)
    # KSV lists are written compactly as "KSV-0001, 0003, ..."
    if "KSV-" in rules:
        for n in re.findall(r"\b(\d{4})\b", rules):
            rows.setdefault(("rule", f"KSV-{n}"), exc)

for f in glob.glob("infra/**/*.tf", recursive=True):
    for n, line in enumerate(open(f), 1):
        m = re.search(r"#checkov:skip=([A-Z0-9_]+):(EXC-\d+)?", line)
        if m and (not m.group(2) or m.group(2) not in rows):
            errors.append(f"{f}:{n}: checkov skip {m.group(1)} has no EXC-nnn row in SECURITY-EXCEPTIONS.md")

for n, line in enumerate(open(".trivyignore"), 1):
    line = line.strip()
    if not line or line.startswith("#"):
        continue
    rule = line.split()[0]
    if "exp:" not in line:
        errors.append(f".trivyignore:{n}: {rule} has no exp: date")
    if ("rule", rule) not in rows:
        errors.append(f".trivyignore:{n}: {rule} has no row in SECURITY-EXCEPTIONS.md")

active = {k: v for k, v in rows.items() if isinstance(k, str)}
print(f"exceptions: {len(active)} registered, next expiry {min(active.values()) if active else '-'}; problems: {len(errors)}")
for e in errors:
    print("  EXCEPTION", e)
sys.exit(1 if errors else 0)
