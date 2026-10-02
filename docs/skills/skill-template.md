<!-- Copy to .claude/skills/<skill-name>/SKILL.md and fill in. Delete these comments.
     Guide: docs/skills/README.md. Keep the body under ~150 lines; move detail to references/. -->
---
name: <skill-name>                 # lowercase-hyphen, same as the folder, ≤ 64 chars
description: <What it does, concretely: tools, inputs, output>. Use when <the phrases a user would say>. Not for <near misses> (use <other skill>).
---

# <Skill title>

<One or two sentences: the job, and what "done" looks like.>

## Guardrails (apply throughout)
- <Scope / authorisation rule>
- <What never to print or change>
- <Never invent results; report gaps>

## Step 1: Establish scope
<What to find out before acting, and where to look for it. Ask if unclear.>

## Step 2: <Deterministic step>
```bash
.claude/skills/<skill-name>/scripts/<script> <args>
```
<What it produces; what to do if a tool is missing.>

## Step 3: <Judgement step>
Apply the rules in `references/<rules>.md`. The core test:
> <The one-sentence decision rule.>

## Step 4: <Verify>
<How to confirm the result: a command, a check, a sample.>

## Step 5: Report
Use `references/<format>.md`. Deliver, in this order:
1. <Summary>
2. <Main table>
3. <What was set aside, with reasons>
4. <Next actions>
5. <Gaps>
