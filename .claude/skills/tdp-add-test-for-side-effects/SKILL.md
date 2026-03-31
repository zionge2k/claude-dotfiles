---
name: tdp-add-test-for-side-effects
description: Add tests to detect unexpected mutations of input or shared state.
argument-hint: "[method-name]"
disable-model-invocation: true
---

Add the following prompt

## Prompt

Check if this method has side effects like modifying input arguments or static state.
Write a unit test that will fail if any such side effects occur.
