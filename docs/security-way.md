# The Security Way: How This Lab Operates

These are the rules we work by. They are also the habits interviewers look for.

## Ethics and scope
1. **Only test what you own or are authorised to test.** Written permission and an agreed scope come first in real jobs. Here the scope is the local kind cluster and nothing else.
2. **Keep the vulnerable app off the network.** Port-forwards bind to `127.0.0.1`. Never expose Juice Shop on a public IP or a shared network.
3. **Report, don't exploit further than needed.** Show that a weakness is real, record it, and move to the fix.

## Engineering habits
4. **Secure by default, not by memory.** Prefer controls that are enforced (policy, CI gate) over ones that rely on people remembering.
5. **Shift left, but also shield right.** Catch issues in code and CI, and still detect and respond at runtime, because prevention will sometimes fail.
6. **Every finding gets a record.** Use the [finding template](templates/finding.md): what, where, risk, fix, how it was verified.
7. **Every exception expires.** Accepting a risk is allowed, but it needs an owner, a reason and an expiry date.
8. **Secrets never go in Git.** They are created locally with `kubectl create secret`, and later phases add a secrets scanner to CI to enforce this.
9. **Pin versions.** Images, charts and tools are pinned so that scans are reproducible and upgrades are deliberate.
10. **Evidence over opinion.** Every phase guide shows the command, the real output, and how the fix was verified.
