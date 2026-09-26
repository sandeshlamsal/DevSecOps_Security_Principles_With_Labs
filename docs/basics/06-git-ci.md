# Baby Step 6: Git and CI

## The concepts
- **Git remembers everything.** Deleting a secret in a new commit doesn't remove it from history. Anyone with the repo can
  still find it. A leaked secret must be **rotated**, not just deleted.
- **Pull requests** are where review happens, and so are automated security checks.
- **CI/CD** (e.g. GitHub Actions) runs scripts on every change. It usually holds powerful credentials (to push images, to deploy),
  which makes the **pipeline itself a high-value target**.
- **Branch protection** makes checks and reviews mandatory rather than optional.

## Try it
```bash
cd "$(git rev-parse --show-toplevel)"
cat .github/workflows/ci.yml       # what runs on every push; note `permissions: contents: read` (least privilege for CI)
make ci                            # the same checks, locally
git log -p --all -S 'password' | head   # search ALL history for a word; this is how leaked secrets are found
```

## Check yourself
1. You committed a password and removed it in the next commit. Is it safe now? What must you do?
2. Why does the CI workflow set `permissions: contents: read`?
3. Name two ways a CI pipeline could be attacked.
