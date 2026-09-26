#!/usr/bin/env python3
"""Fail if a relative markdown link points to a missing file, or if any page isn't linked from INDEX.md."""
import glob, os, re, sys

SKIP = ("tmp/", "reports/")
pages = [f for f in glob.glob("**/*.md", recursive=True) if not f.startswith(SKIP)]
bad = []
for f in pages:
    for link in re.findall(r"\]\(([^)#]+?)(?:#[^)]*)?\)", open(f).read()):
        if link.startswith(("http://", "https://", "mailto:")): continue
        if not os.path.exists(os.path.normpath(os.path.join(os.path.dirname(f), link))): bad.append(f"{f}: {link}")

indexed = {os.path.normpath(l) for l in re.findall(r"\]\(([^)#]+?)(?:#[^)]*)?\)", open("INDEX.md").read())}
missing = sorted(p for p in pages if p != "INDEX.md" and os.path.normpath(p) not in indexed)

print(f"checked markdown links; broken: {len(bad)}; pages missing from INDEX.md: {len(missing)}")
for b in bad: print("  BROKEN", b)
for m in missing: print("  NOT IN INDEX", m)
sys.exit(1 if bad or missing else 0)
