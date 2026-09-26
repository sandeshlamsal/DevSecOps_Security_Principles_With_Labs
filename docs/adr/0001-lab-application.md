# ADR-0001: Lab application

- **Status:** Accepted
- **Date:** 2026-09-26

## Context
We need an app to learn security engineering on: finding weaknesses, fixing them, preventing regressions in CI,
hardening where it runs, and detecting misuse. It must run locally on Kubernetes, and be **legal and safe to test**.

## Options considered
| Option | Pros | Cons |
|---|---|---|
| **OWASP Juice Shop** | OWASP flagship project, actively maintained, covers the OWASP Top 10 and more, built-in score board to track learning, single container, a real modern stack (Node.js, Angular, SQLite) with a real dependency tree for SCA | Single service, so fewer microservice-level lessons |
| DVWA / WebGoat | Classic, well documented | Older stacks; less realistic modern app |
| OpenTelemetry Astronomy Shop (used in the SRE lab) | Real microservices, good for supply-chain and runtime phases | Few application-level weaknesses to learn from |
| A custom app | Fully understood | Unrealistic; you only find what you planted |

## Decision
Use **OWASP Juice Shop**, image pinned (`v20.2.0`), deployed with a plain manifest so every hardening change is a visible diff.
The Astronomy Shop remains an option for multi-service exercises in later phases (e.g. NetworkPolicy between services).

## Consequences
- The app is intentionally insecure, so it is only reachable on `127.0.0.1`.
- Each phase hardens the same manifest and pipeline, so progress shows up as a Git history of security improvements.
