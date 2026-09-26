# ADR-0003: The portfolio capstone lives in this repo

- **Status:** Accepted
- **Date:** 2026-09-26

## Context
Phase 5 of the roadmap is a portfolio project: a GitOps pipeline hardened end to end. It could be a separate showcase repo, or part of this one.

## Decision
Build it **in this repo**, incrementally from Phase 3. The audited app (Juice Shop, with fixes from the [remediation plan](../../findings/REMEDIATION.md))
is what the pipeline ships, so the repo tells one story: principles → labs → audit → fixes → a pipeline that keeps them fixed.

## Consequences
- The capstone design is in [docs/capstone/](../capstone/README.md); its code lives in the normal places (`.github/workflows/`, `gitops/`, `platform/`, `infra/`).
- The top-level README must make the capstone easy to find for a recruiter skimming in 2 minutes.
