# 08: Identity and Access (Authentication, Sessions, Authorisation)

> "Authentication asks who you are. Authorisation asks what you may do. Both must be checked on every request."

## In plain words
- **Authentication (authn):** proving identity. Something you know (password), have (phone, security key) or are (fingerprint).
  **MFA** combines two or more.
- **Session management:** after login, a token or cookie represents you. It must be unguessable, expire, be invalidated on
  logout, and travel only over TLS (`Secure`, `HttpOnly`, `SameSite` cookie flags).
- **Authorisation (authz):** checking permissions **on the server, for every request, for every object**.
  The #1 web risk in the OWASP Top 10 (2021) is **Broken Access Control**. A classic example: changing `/api/orders/1001`
  to `/api/orders/1002` and seeing someone else's order. This is called IDOR (insecure direct object reference).

Passwords must be stored with a slow, salted hash designed for passwords (**Argon2id, bcrypt, scrypt**), never with plain
MD5/SHA or reversible encryption.

## Why it matters
- **Optus (2022):** an API endpoint that returned customer records reportedly didn't require authentication, and the records
  had sequential identifiers. Data on millions of customers was exposed.
- **Uber (2022):** an attacker with a stolen password sent repeated MFA push requests until an employee accepted one
  ("MFA fatigue"). Push-based MFA without number matching can be socially engineered.

## In our lab
Juice Shop uses JWT tokens and has deliberately weak authentication and authorisation. You review its design and code,
then write the controls, rather than breaking into other accounts.

## Hands-on labs

### Lab 8.1: Inspect your own session ⏳
1. Register an account, log in, and copy **your own** token from DevTools (Application → Local Storage / Cookies).
2. Decode it at the command line: `cut -d. -f2 <<< "$TOKEN" | base64 -d 2>/dev/null`. List what's inside, and flag anything
   sensitive that shouldn't be in a token (JWTs are *encoded*, not encrypted).
3. Check the cookie flags and token lifetime. Write findings for anything missing.

### Lab 8.2: Authorisation review in code ⏳
1. In the Juice Shop source (`tmp/juice-shop/routes/`), find the handlers for baskets and orders.
2. For each handler, answer: does it check that the object belongs to the logged-in user? Where?
3. Write one finding for a missing object-level check, with the fix (compare the owner ID in the token with the owner of the record).

### Lab 8.3: Password storage review ⏳
Find how Juice Shop hashes passwords (`lib/insecurity.ts`). Explain why that algorithm is weak for passwords, and what you
would migrate to and how (rehash on next login).

## Best-practice checklist
- [ ] MFA for all staff; phishing-resistant (FIDO2/WebAuthn) for admins
- [ ] Authorisation enforced server-side, per object, with deny by default
- [ ] Passwords hashed with Argon2id or bcrypt; checked against breached-password lists
- [ ] Sessions expire, rotate on login, and are invalidated on logout and password change
- [ ] Login has rate limiting and alerting on credential-stuffing patterns

## Interview questions
1. Authentication vs authorisation: explain with an example of each failing.
2. What is IDOR, and how do you prevent it systematically, not endpoint by endpoint?
3. What's in a JWT? What are common JWT mistakes?
4. Why bcrypt/Argon2 instead of SHA-256 for passwords?
5. Session cookies vs tokens in local storage: what are the security trade-offs?
6. How would you defend against MFA fatigue attacks?
