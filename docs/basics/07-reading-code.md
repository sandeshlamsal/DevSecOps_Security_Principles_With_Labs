# Baby Step 7: Reading Code for Security

## The concepts
Most security code review is **source → sink** tracing:
- **Source:** where untrusted data enters: `req.body`, `req.query`, `req.params`, headers, cookies, uploaded files, LLM output.
- **Sink:** where data could become dangerous: a SQL query, `exec`/`spawn`, `innerHTML`/`bypassSecurityTrust*`, a file path,
  `fetch(url)` on the server, `eval`, a redirect.
- **Sanitiser/control:** what stands between them: parameter binding, validation, encoding, an authorisation check.

**Question to ask at every sink:** "Can untrusted data reach here, and is there a correct control on *every* path?"

## Try it
```bash
git clone --depth 1 --branch v20.2.0 https://github.com/juice-shop/juice-shop.git "$(git rev-parse --show-toplevel)/tmp/juice-shop"
cd "$(git rev-parse --show-toplevel)/tmp/juice-shop"
grep -rn "sequelize.query" routes/ | head          # SQL sinks
grep -rn "req.body\|req.query\|req.params" routes/ | wc -l   # how many sources?
```
Pick one `sequelize.query` hit. Read upward in the function: where does each value in the query come from? Is it bound as a
parameter, or pasted into the string?

## Check yourself
1. Define source, sink and sanitiser in one sentence each.
2. Why is `innerHTML` a sink but `textContent` isn't?
3. Why should LLM output be treated as a source?
