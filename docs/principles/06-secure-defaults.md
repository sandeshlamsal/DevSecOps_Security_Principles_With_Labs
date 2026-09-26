# 06: Secure Defaults and Failing Securely

> "The easy path should be the secure path."

## In plain words
- **Secure defaults:** a system should be safe *out of the box*. Security features are on by default, and anyone who
  wants something less safe has to opt out on purpose (and it should be visible when they do).
- **Fail securely:** when something breaks, it should deny access rather than allow it, and error messages shouldn't
  reveal internals (stack traces, SQL, file paths, versions).

## Why it matters
**Microsoft Power Apps portals (2021):** a default setting left certain data lists publicly readable. Organisations that
didn't change it exposed around 38 million records, including contact-tracing and vaccination data. The fix was to
change the default.

## In our lab
- ❌ **F-007:** `Access-Control-Allow-Origin: *`, so any website can read responses from the API in a user's browser.
- ❌ **F-008:** no `Content-Security-Policy` header, which removes a strong second layer against cross-site scripting (XSS).
- ✅ Good: `X-Content-Type-Options: nosniff` and `X-Frame-Options: SAMEORIGIN` are already set.

## Hands-on labs

### Lab 6.1: Security-header review ⏳
1. `curl -sI http://127.0.0.1:3000/` and compare the output with the [OWASP Secure Headers](https://owasp.org/www-project-secure-headers/) recommendations.
2. For each missing header, write what it prevents and whether it applies here (for example, HSTS only matters over HTTPS).
3. Draft a CSP that allows only the app's own origin. Test it in **report-only** mode first
   (`Content-Security-Policy-Report-Only`) and read the violations in the browser console.

### Lab 6.2: Error handling ⏳
1. Request a route that doesn't exist, and send malformed JSON to an API.
2. Record what the error reveals (framework, versions, stack traces, file paths).
3. Write the fix as a finding: generic error to the user, full detail to the server log with a correlation ID.

## Best-practice checklist
- [ ] New services start from a hardened template (headers, TLS, auth, logging on by default)
- [ ] CORS allows specific origins, never `*` together with credentials
- [ ] Errors are generic to users and detailed only in server logs
- [ ] Authorisation failures default to deny
- [ ] Default credentials are impossible (forced change, or none at all)

## Interview questions
1. What does "secure by default" mean? Give an example from a cloud service.
2. Explain CORS. Why is `Access-Control-Allow-Origin: *` sometimes fine and sometimes dangerous?
3. What does a Content Security Policy protect against, and how do you roll one out safely?
4. What is "failing open" vs "failing closed"? When might failing open be the right call?
5. What information should never appear in an error message?
