# ADR-0002: Cloud provider for Phase 2

- **Status:** Accepted
- **Date:** 2026-09-26

## Context
The roadmap says to go deep on one cloud rather than wide. The choice sets the certification target and the cloud labs.

## Options considered
| Option | Pros | Cons |
|---|---|---|
| **Azure** | Builds on the SRE lab's AKS + Terraform work; AZ-500 is well respected; Entra ID is common in enterprises | Slightly smaller job market than AWS |
| AWS | Largest market; AWS Security Specialty is highly valued | Start over on Terraform and EKS |
| GCP | Strong Kubernetes story | Smallest market for these roles |

## Decision
**Azure**, with the **AZ-500** certification. Cloud labs use [infra/azure/](../../infra/azure/).

## Consequences
- Phase 2 labs are Azure-specific (Entra ID, Azure RBAC, Key Vault, Defender for Cloud, Azure Policy); the principles transfer to AWS/GCP.
- A later "AWS equivalents" page is a cheap way to show breadth in interviews.
