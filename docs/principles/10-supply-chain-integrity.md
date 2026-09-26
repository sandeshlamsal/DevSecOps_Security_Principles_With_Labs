# 10: Software Supply-Chain Integrity

> "You ship far more code than you write. Know it, patch it, and prove where it came from."

## In plain words
A typical app is **80–90% third-party code**: libraries, base images and build tools. The supply chain is everything between
a developer's keyboard and production. Securing it means answering four questions:

| Question | Practice | Tools in this lab |
|---|---|---|
| What's in it? | **SBOM** (Software Bill of Materials) | Syft, Trivy |
| Is any of it known-vulnerable? | **SCA** (software composition analysis) against CVE databases | Trivy, Grype, `npm audit` |
| Did it really come from us, unmodified? | **Signing** and **provenance** | Cosign (Sigstore), SLSA |
| Is only trusted stuff allowed to run? | **Admission policy** that verifies signatures | Kyverno |

Also: pin versions by **digest** (a tag like `v20.2.0` can be moved to a different image; a digest can't).

## Why it matters
- **SolarWinds (2020):** attackers compromised the vendor's build system and inserted a backdoor into signed software updates,
  delivered to about 18,000 customers.
- **Log4j (2021):** most affected organisations first had to find out *whether* they used it. Those with SBOMs answered in
  minutes; others took weeks.
- **xz utils (2024):** a maintainer identity built trust over two years, then slipped a backdoor into a compression library used
  by SSH on Linux. It was caught by chance, just before reaching major stable distributions.

## In our lab
- ⚠️ **F-009:** the image is pinned by tag, not digest.
- Juice Shop has a large npm dependency tree, some of it deliberately outdated, so it's realistic SCA material.

## Hands-on labs

### Lab 10.1: Generate an SBOM ⏳
1. `brew install syft trivy`
2. `syft bkimminich/juice-shop:v20.2.0 -o cyclonedx-json > reports/sbom.cdx.json`
3. Count the components, and find answers to: "Do we ship library X? Which version?" That's the Log4j question.

### Lab 10.2: Vulnerability scan and triage ⏳
1. `trivy image --severity HIGH,CRITICAL bkimminich/juice-shop:v20.2.0`
2. For the top 5 CVEs, decide: is the vulnerable code **reachable** in this app? Is there a fixed version? Fix, accept (with expiry)
   or mark not-affected? Record it with a [VEX](https://www.cisa.gov/sbom)-style justification.
3. Explain why "0 CVEs" is a poor goal, and "no exploitable, unaccepted CRITICALs in production" is a better one.

### Lab 10.3: Sign and verify ⏳
1. Run a local registry, push your own build of Juice Shop, and sign it with `cosign sign` (key pair generated locally).
2. Install Kyverno and add a policy that only admits images signed by your key.
3. Try to deploy the unsigned upstream image and capture the rejection. Then pin the deployment by digest and close F-009.

## Best-practice checklist
- [ ] Every build produces an SBOM, stored with the artifact
- [ ] Dependencies are scanned in CI and continuously in the registry (new CVEs appear for old images)
- [ ] Images are pinned by digest, signed, and verified at admission
- [ ] Dependency updates are automated (Dependabot/Renovate) and small
- [ ] Build systems are hardened and isolated (SLSA levels as the roadmap)

## Interview questions
1. What is an SBOM, and how would it have helped during Log4Shell?
2. How do you prioritise 300 CVEs in a container image?
3. Tag vs digest pinning: why does it matter?
4. What is SLSA? What does build provenance prove?
5. How would you detect a malicious dependency, which by definition has no CVE yet?
