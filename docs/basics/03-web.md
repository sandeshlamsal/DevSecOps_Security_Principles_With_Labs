# Baby Step 3: How the Web Works

## The concepts
- **HTTP request:** a method (`GET`, `POST`…), a path, **headers**, and sometimes a **body**. Everything in it is controlled by the
  client, which means it's untrusted.
- **HTTP response:** a status code (`200` OK, `302` redirect, `401` not authenticated, `403` not allowed, `404` not found, `500` server error),
  headers and a body.
- **Cookies and sessions:** HTTP forgets you between requests, so after login the server gives you a cookie or token to send back each
  time. Whoever holds it *is* you, so protecting it matters.
- **Same-origin policy:** the browser stops one site's scripts from reading another site's data. **CORS** is how a server relaxes that on purpose.
- **Security headers:** instructions from the server to the browser (e.g. `Content-Security-Policy`, `Strict-Transport-Security`).

## Try it (with the lab running: `make open`)
```bash
curl -si http://127.0.0.1:3000/api/Products | head -20    # status line, headers, then the body
curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:3000/does-not-exist
```
In the browser, open http://localhost:3000, press F12 → **Network**, and click around. Pick one request and find its method,
status, request headers, response headers and cookies. Then look at **Application → Cookies / Local Storage**.

## Check yourself
1. `401` vs `403`: what's the difference?
2. Why must the server re-check everything, even if the browser form already validated it?
3. What does the same-origin policy protect, and what does CORS change?
