# Juice Shop: Asset Inventory and CIA Rating

- **Lab:** [1.1](../docs/principles/01-cia-triad-and-risk.md) · **Date:** 2026-09-26 · **App version:** 20.2.0
- **Method:** used the shop as a customer, then read the data model (`models/*.ts`), key handling (`lib/insecurity.ts`),
  config (`config/default.yml`) and the public file area (`ftp/`) in the pinned source. Execution record: [lab-01](../docs/labs/lab-01-cia-and-risk.md).
- **Classification:** Public · Internal · Confidential · Restricted (highest: breach causes legal, financial or total-compromise impact)
- **Ratings:** how bad is a failure of each property for this asset? H = High, M = Medium, L = Low

## Data assets

| # | Asset | Where it lives (source) | Contains | Class | C | I | A | Why |
|---|---|---|---|---|---|---|---|---|
| A1 | Customer credentials | `Users` table (`models/user.ts`) | email, password hash, role, TOTP secret, last login IP | Restricted | **H** | **H** | M | Account takeover; `role` decides who is admin |
| A2 | Security answers | `SecurityAnswers` (`models/securityAnswer.ts`) | answers used for password reset | Restricted | **H** | **H** | L | A password-equivalent: reveals or resets access |
| A3 | Payment cards | `Cards` (`models/card.ts`) | name, card number, expiry | Restricted | **H** | **H** | L | Card fraud; PCI DSS scope |
| A4 | Addresses and phone numbers | `Addresses` (`models/address.ts`) | name, street, city, zip, mobile | Confidential | **H** | M | L | Personal data (GDPR) |
| A5 | Wallet balance | `Wallets` (`models/wallet.ts`) | stored money | Confidential | M | **H** | M | Changing it = stealing money |
| A6 | Orders, baskets, coupons | `Baskets`, `BasketItems`, order records | what was bought, at what price, discounts | Confidential | M | **H** | **H** | Wrong orders or prices = direct loss; checkout down = no revenue |
| A7 | Product catalogue and prices | `Products` (`models/product.ts`) | names, descriptions, prices | Public | L | **H** | **H** | Public by design, but a changed price is fraud |
| A8 | Reviews, feedback, complaints (+ uploaded files) | `Feedbacks`, `Complaints`, `uploads/complaints` | free text, ratings, files | Internal | M | M | L | Defacement; stored-XSS carrier; complaints may hold personal details |
| A9 | Photo "memories" | `Memories` (`models/memory.ts`) | user images + captions | Confidential | M | M | L | Personal content |
| A10 | Data-deletion requests | `PrivacyRequests` | who asked to be erased | Confidential | M | **H** | M | Legal obligation (GDPR right to erasure) |
| A11 | Documents in the file area | `ftp/` | business docs, a password-manager database (`incident-support.kdbx`), backup files | Confidential | **H** | M | L | Served publicly today (F-005) |

## Secrets and identities (assets that protect other assets)

| # | Asset | Where | Class | C | I | A | Why |
|---|---|---|---|---|---|---|---|
| S1 | JWT signing private key | **hard-coded** in `lib/insecurity.ts:21` | Restricted | **H** | **H** | M | Whoever has it can mint a valid session for **any** user, including admins → it protects A1–A11 at once (F-010) |
| S2 | Kubernetes service-account token | mounted in the pod | Confidential | M | M | L | API access to the cluster from inside the app (F-001) |
| S3 | LLM endpoint configuration | `config/default.yml` (`chatBot.llmApiUrl`) | Internal | M | M | L | Today points to `localhost:11434` (inactive). Once connected, the model can reach whatever the chatbot is given (Principle 13) |

## Service assets

| # | Asset | C | I | A | Why |
|---|---|---|---|---|---|
| V1 | The shop being available (browse, login, checkout) | – | – | **H** | Revenue and trust |
| V2 | The database file `data/juiceshop.sqlite` **inside the container** | (as A1–A10) | **H** | **H** | No volume, no backup: a pod restart **erased** a newly registered customer (F-012) |
| V3 | The container image | L | **H** | M | Tampered image = attacker code in production (Principle 10) |

## What this tells us (priorities for the next principles)

1. **S1 is the crown jewel.** One secret protects every data asset, and it's in public source code. Nothing else matters much until it's rotated out of the code (Principle 09).
2. **A1–A3 are Restricted.** They need the strongest controls: password hashing is plain MD5 today (F-011, Principle 08).
3. **Integrity matters as much as confidentiality** for A5–A7: this is a shop, and changed prices or balances are direct fraud.
4. **Availability is fragile** (V2): no persistent storage or backup. For a training app that's by design; in production it'd be a top risk.
