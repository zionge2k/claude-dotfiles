---
name: tdp-add-test-for-change-later
description: Add tests that protect against future changes — think like a maintainer, not just a builder.
argument-hint: "[method-name]"
disable-model-invocation: true
---

Add the following prompt

## Prompt

Based on this code, what would break or behave differently if I changed the underlying implementation later (e.g., switched from List to Set)?
Write tests that assert expected behavior to help catch such regressions.
