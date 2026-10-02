# Output formats

## Funnel (one row per tool)
| Tool | Raw | Needs review | Real, in scope |
|---|---|---|---|

## Findings table
| ID | Severity | Finding | Location | Evidence (redacted) | Fix |
|---|---|---|---|---|---|
| F-001 | High | SQL built from request data | `routes/login.ts:34` | `` `…WHERE email = '${req.body.email}'` `` | Parameterised query / ORM bind |

Severity is **risk in context** (Critical / High / Medium / Low), not the scanner's label. One finding may cover several identical hits.

## Set-aside table
| Tool | Group | Count | Reason (sampled N) |
|---|---|---|---|
| gitleaks | `*.spec.ts` | 62 | Dummy tokens in unit tests (sampled 3) |

## Full finding (when the repo keeps a register)
```
# F-<n>: <short title>
| Found | date, tool | Location | file:line / URL | Category | CWE, OWASP |
| CIA | C/I/A | Risk | likelihood × impact → level | Status | Open / Fixed / Accepted (owner, expiry) |
Description · Evidence (command + redacted output) · Recommendation (right layer + second layer) · Verification (command + the CI gate that keeps it fixed)
```
