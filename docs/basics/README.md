# Baby Steps: Fundamentals Before the Principles

Short, plain-English lessons on what every security role assumes you already know. Each lesson is **about 30–60 minutes**:
read the concept, run the small "try it" exercises on your own machine, then answer the "check yourself" questions
without looking back.

You don't need to master these before starting the [principles](../principles/README.md). Do lessons 1–3 first, then
come back to the others when a principle refers to them.

| # | Lesson | You'll be able to… | Used in principles |
|---|---|---|---|
| 1 | [How computers talk: networking](01-networking.md) | Explain IP, ports, TCP, DNS and TLS, and see them with real commands | 04, 05 |
| 2 | [Linux for security](02-linux.md) | Read users, permissions, processes and logs | 03, 12 |
| 3 | [How the web works](03-web.md) | Read an HTTP request/response, cookies and headers in DevTools | 06, 07, 08 |
| 4 | [Crypto without the maths](04-crypto.md) | Tell hashing, encryption, encoding and signing apart, and use each | 08, 09, 10 |
| 5 | [Containers and Kubernetes](05-containers-kubernetes.md) | Explain images, pods, namespaces, service accounts and RBAC | 03, 04, 10 |
| 6 | [Git and CI](06-git-ci.md) | Explain why Git history and pipelines are security-relevant | 09, 11 |
| 7 | [Reading code for security](07-reading-code.md) | Trace untrusted input from a *source* to a dangerous *sink* | 07, 08, 13 |
| 8 | [Frameworks cheat sheet](08-frameworks.md) | Know what OWASP, CWE, CVE, CVSS, NIST CSF, CIS, ATT&CK, ISO 27001 and SOC 2 are for | All |

**Tip:** keep a learning log (for example `notes/` in a private fork). Writing one paragraph per lesson, in your own words,
is the fastest way to be ready to explain it in an interview.
