# Baby Step 4: Crypto Without the Maths

## The concepts
| | What it does | Reversible? | Key? | Use it for |
|---|---|---|---|---|
| **Encoding** (Base64, hex) | Changes format | Yes, by anyone | No | Transport. **Never** security |
| **Hashing** (SHA-256) | Fixed-size fingerprint | No | No | Integrity checks, file identity |
| **Password hashing** (Argon2id, bcrypt) | *Slow*, salted hash | No | No | Storing passwords |
| **Symmetric encryption** (AES-GCM) | Scrambles data | Yes, with the key | One shared key | Data at rest, bulk data |
| **Asymmetric** (RSA, ECDSA, Ed25519) | Key pair: public + private | Yes / verify | Key pair | TLS key exchange, **digital signatures** |
| **Signing** | Proves who produced data, and that it wasn't changed | — | Private key signs, public verifies | Software releases, container images, JWTs |

Rule one: **never invent your own crypto.** Use well-known libraries and defaults.

## Try it
```bash
echo -n 'hello' | base64                     # aGVsbG8=  ← anyone can reverse this
echo 'aGVsbG8=' | base64 -d
echo -n 'hello' | shasum -a 256              # change one letter and the whole hash changes
openssl rand -base64 32                      # a strong random secret
openssl genpkey -algorithm ed25519 -out /tmp/k.pem && openssl pkey -in /tmp/k.pem -pubout   # a key pair
```

## Check yourself
1. Why is Base64 not encryption?
2. Why are passwords stored with a *slow* hash?
3. What does a signature on a container image prove?
