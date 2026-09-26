# 05: Minimise the Attack Surface

> "The code, ports and features you don't have can't be attacked."

## In plain words
The **attack surface** is every place an attacker can interact with your system: open ports, URLs, APIs, file uploads,
admin panels, debug endpoints, installed packages, and even the people with access. Each one is a door. Close the doors
you don't need, and lock and watch the ones you keep.

Ways to shrink it:
- **Remove**: unused features, endpoints, packages, shells and tools in images
- **Restrict**: bind to localhost, put admin and metrics endpoints on a separate internal port, require authentication
- **Hide nothing important behind obscurity**: an unlinked URL is still public

## Why it matters
Thousands of databases and search clusters have been found open on the internet with no authentication, exposing
billions of records in total. Nobody attacked them in a clever way. They were simply reachable, and discovered by
routine internet-wide scanning.

## In our lab
- ✅ Good: distroless image, so there's no shell or package manager for an attacker to use (`exec: "ls": executable file not found`).
- ❌ **F-005:** `/ftp` is a public directory listing with internal-looking documents (for example `acquisitions.md`).
- ❌ **F-006:** `/metrics` (Prometheus) is served on the same public port with no authentication.

## Hands-on labs

### Lab 5.1: Enumerate your own attack surface ⏳
1. From the browser's DevTools network tab and `main.js`, list every API route the frontend calls.
2. Check each one with `curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:3000<path>` **without logging in**.
3. Build a table: route, requires auth (yes/no), what it exposes, whether it's needed. That table is your attack-surface inventory.

### Lab 5.2: Image attack surface ⏳
1. Compare the Juice Shop image with a full `node:22` image: size, package count and whether a shell exists.
   (Package counts come in Principle 10 with an SBOM tool.)
2. Explain in two sentences why distroless reduces risk, and what it makes harder (debugging), plus how to debug anyway
   (`kubectl debug` with an ephemeral container).

### Lab 5.3: Close the doors ⏳
1. Decide, for F-005 and F-006, whether to remove, restrict or accept. Record the reasoning in the finding.
2. Implement it at the layer you control (for example, an ingress rule that blocks `/ftp` and `/metrics` from outside).
   Note the trade-off: fixing it at the edge is fast, fixing it in the app is durable. Real teams often do both.

## Best-practice checklist
- [ ] There's an up-to-date inventory of exposed endpoints and ports
- [ ] Admin, debug and metrics endpoints aren't on the public listener
- [ ] Production images contain no shells, compilers or package managers unless required
- [ ] Unused features and dependencies are removed, not just disabled
- [ ] External exposure is scanned continuously, not once

## Interview questions
1. What is an attack surface? How would you measure it for a web app?
2. Why is "security through obscurity" not a control on its own?
3. What are distroless images, and what are the trade-offs?
4. How would you debug a production container that has no shell?
5. Where should a metrics endpoint live, and why?
