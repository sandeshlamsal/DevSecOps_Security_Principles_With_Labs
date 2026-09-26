# Lab 1: CIA Triad and Risk (Execution Guide)
**Lab 1** · [All labs](README.md) · [Principle 01](../principles/01-cia-triad-and-risk.md) · [← Lab 0](lab-00-foundation.md)

> **Goal:** know what Juice Shop holds that's worth protecting, rate each asset for confidentiality, integrity and
> availability, and use that to rank risks.
> **Deliverable:** [threat-models/juice-shop-assets.md](../../threat-models/juice-shop-assets.md)
> **Time:** about 1 hour. **Executed:** 2026-09-26.

---

## Step 1: Use the shop as a customer

Register and log in through the same API calls the web page makes (DevTools → Network shows them):
```bash
B=http://127.0.0.1:3000; E="lab1-$(date +%s)@example.test"; P='Lab1-Passw0rd!'
curl -s -o /dev/null -w 'register: %{http_code}\n' -H 'Content-Type: application/json' \
  -d "{\"email\":\"$E\",\"password\":\"$P\",\"passwordRepeat\":\"$P\",\"securityQuestion\":{\"id\":1},\"securityAnswer\":\"lab\"}" $B/api/Users/
curl -s -H 'Content-Type: application/json' -d "{\"email\":\"$E\",\"password\":\"$P\"}" $B/rest/user/login | head -c 80
```
```
register: 201
{"authentication":{"token":"eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9...     (a 741-character JWT)
```
The browser also asks for addresses, payment cards and a wallet during checkout. Each is a data asset.

## Step 2: Read the data model in the pinned source

```bash
git clone -q --depth 1 --branch v20.2.0 https://github.com/juice-shop/juice-shop.git tmp/juice-shop   # tmp/ is git-ignored
ls tmp/juice-shop/models/
grep -n "storage" tmp/juice-shop/models/index.ts
```
```
address.ts basket.ts basketitem.ts captcha.ts card.ts challenge.ts ... privacyRequests.ts product.ts
securityAnswer.ts securityQuestion.ts user.ts wallet.ts
41:    storage: options?.inMemory ? ':memory:' : 'data/juiceshop.sqlite',
```
Fields that raise the rating (from `models/*.ts`): `user.password`, `user.role`, `user.totpSecret`, `card.cardNum`,
`address.mobileNum`, `securityAnswer.answer`, `wallet.balance`.

## Step 3: Find the secrets that protect everything else

```bash
grep -n "privateKey\|jwt.sign\|createHash" tmp/juice-shop/lib/insecurity.ts | cut -c1-100
grep -n -A5 "chatBot:" tmp/juice-shop/config/default.yml
```
```
21:const privateKey = '-----BEGIN RSA PRIVATE KEY-----\r\nMIICXAIBAAKBgQDNwqLEe9w...     ← F-010
41:export const hash = (data: string) => crypto.createHash('md5').update(data).digest('hex')   ← F-011
54:export const authorize = (user = {}) => jwt.sign(user, privateKey, { expiresIn: '6h', algorithm: 'RS256' })
  chatBot:
    model: 'gemma4:e4b'
    llmApiUrl: 'http://localhost:11434/v1'     ← LLM feature exists but points nowhere inside the pod
```
**Why F-010 is High:** the private key signs every login token. It's in a public repository, so anyone can create a token the
server accepts, for any user. One secret guards every data asset at once.

## Step 4: Test availability and durability

The database is a file inside the container. What happens if the pod dies?
```bash
kubectl -n juice-shop delete pod -l app=juice-shop --wait=true     # 21:46:12Z
kubectl -n juice-shop rollout status deploy/juice-shop
# (restart the port-forward: it dies with the old pod, see L1-ISSUE-2)
curl -s -H 'Content-Type: application/json' -d "{\"email\":\"$E\",\"password\":\"$P\"}" $B/rest/user/login
```
```
Invalid email or password.
```
The customer registered two minutes earlier **no longer exists**. No volume, no backup: every restart resets the shop (F-012).

## Step 5: Rate and rank

Full table: [juice-shop-assets.md](../../threat-models/juice-shop-assets.md): 11 data assets, 3 secrets and identities, 3 service assets.

| Rank | Risk | Asset | Finding |
|---|---|---|---|
| 1 | Anyone can log in as anyone | S1 JWT signing key | F-010 High |
| 2 | Leaked hashes crack fast | A1 credentials | F-011 High |
| 3 | Internal documents and a password-manager file are public | A11 | F-005 High |
| 4 | All data lost on restart | V2 | F-012 Medium (by design here) |

**Lesson:** the scariest-sounding bug isn't always the top risk. The top risk is the one that exposes the **most valuable
asset** to the **most people** with the **least effort**, and here that's a single leaked key.

---

## Lab 1 exit checklist
- [x] Used the shop as a customer; every screen that stores data mapped to an asset
- [x] 17 assets classified and rated for C, I and A
- [x] Secrets and identities treated as assets in their own right
- [x] Availability tested with a real restart, not assumed
- [x] 3 new findings (F-010, F-011, F-012); F-005 evidence strengthened; all ranked by risk

**Interview takeaway:** "What are the most important assets in this system, and how did you decide?" You can answer with a
method (data model + secrets + service), a classification scheme, and a real example of a key protecting everything else.

---

## Issues log

| ID | Step | Symptom | Root cause | Fix | Verified by |
|---|---|---|---|---|---|
| L1-ISSUE-1 | 1 | `GET /rest/user/whoami` with `Authorization: Bearer <token>` returned `{"user":{}}` | That route reads the session from the **`token` cookie** (`routes/currentUser.ts:17`), not the header | Send it as a cookie (`-b "token=$T"`) when testing that route. Lesson: read the code before concluding a feature is broken | Source line confirmed |
| L1-ISSUE-2 | 4 | After deleting the pod, `curl` to `127.0.0.1:3000` failed | `kubectl port-forward` to a Service actually binds to **one pod**; when that pod dies, the tunnel dies | Restart `make open` after any pod restart | Requests succeeded after restarting the port-forward |

---
**Lab 1** · [All labs](README.md) · [Principle 01](../principles/01-cia-triad-and-risk.md) · [← Lab 0](lab-00-foundation.md)
