# 07: Never Trust Input

> "All input is evil until proven otherwise."

## In plain words
Anything that comes from outside your code is **untrusted**: form fields, URLs, headers, cookies, JSON bodies, uploaded
files, and even data from your own database if a user put it there. **Injection** happens when untrusted data is treated as
**code or commands** by an interpreter (SQL, a shell, HTML/JavaScript in a browser, a template engine, a log formatter).

The defences, in order of strength:
1. **Keep data and code separate:** parameterised queries, safe APIs that don't invoke a shell, templating that auto-escapes.
2. **Validate input:** allow-list the expected type, length, format and range. Reject everything else.
3. **Encode output for its context:** HTML, attribute, JavaScript and URL contexts each need different encoding.
4. **Add second layers:** CSP ([06](06-secure-defaults.md)), a least-privileged DB user ([03](03-least-privilege.md)), a WAF.

| Weakness (CWE) | Untrusted data ends up in… | Primary fix |
|---|---|---|
| SQL injection (CWE-89) | A SQL query string | Parameterised queries / ORM bindings |
| Cross-site scripting (CWE-79) | HTML or JavaScript sent to a browser | Context-aware output encoding + CSP |
| OS command injection (CWE-78) | A shell command | Avoid the shell; pass argument arrays |
| Path traversal (CWE-22) | A file path | Canonicalise, then check against an allow-listed base dir |
| SSRF (CWE-918) | A URL the server fetches | Allow-list destinations; block internal ranges |

## Why it matters
**Log4Shell (2021):** a widely used Java logging library interpreted special lookup strings *inside logged data*. Any app that
logged a user-controlled value (a username, a header) could be made to load and run remote code. It affected a huge share of
Java software worldwide, and it came from treating input as instructions.

## In our lab
Juice Shop is deliberately full of injection weaknesses. In this principle you find them the way an AppSec engineer does:
**by reading code with tools**, then fixing them and proving the fix, rather than by attacking the app.

## Hands-on labs

### Lab 7.1: Find injection sinks with SAST ✅ ([execution guide](../labs/lab-07-sast-supply-chain.md))
1. Get the source for the pinned version: `git clone --depth 1 --branch v20.2.0 https://github.com/juice-shop/juice-shop.git tmp/juice-shop`
2. Scan it: `semgrep scan --config p/owasp-top-ten --config p/nodejs tmp/juice-shop --json -o reports/semgrep.json`
3. Pick the top 5 SQL-injection and XSS results. For each one, open the code and decide: **true positive** or **false positive**,
   and why. Triage skill is what AppSec interviews test most.

### Lab 7.2: Fix one injection properly ⏳
1. Take one confirmed SQL-injection finding. Rewrite the query using parameter binding (Sequelize replacements).
2. Build your own image from the fixed source, deploy it to the lab and confirm the feature still works.
3. Re-run Semgrep and confirm the finding is gone. Record before/after in the finding.

### Lab 7.3: Write a custom rule ✅ ([execution guide](../labs/lab-07-sast-supply-chain.md))
Write a small Semgrep rule that flags string concatenation into `sequelize.query(...)`, and add it to CI in Principle 11 so this
class of bug can't come back. **Turning one fix into a guardrail** is the core DevSecOps move.

## Best-practice checklist
- [ ] Queries are always parameterised; string-built SQL fails code review and CI
- [ ] Input is validated against an allow-list schema at the API boundary
- [ ] Output encoding is automatic in the templating layer
- [ ] Every fixed vulnerability class gets a regression test or a SAST rule
- [ ] Developers are trained on the top weaknesses in *your* codebase, not generic lists

## Interview questions
1. Explain SQL injection and how parameterised queries prevent it.
2. Stored vs reflected vs DOM-based XSS: how do they differ, and how do you prevent each?
3. Why is input validation alone not enough to stop XSS?
4. What is SSRF, and why is it especially dangerous in cloud environments?
5. A SAST tool reports 400 findings. How do you triage them with a team of two?
