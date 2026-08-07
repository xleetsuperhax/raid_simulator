# Test Case Format

One file per encounter (e.g. `docs/testing/boss-01.md`), containing test cases in the format below. Test cases should target specific conditions — especially edge cases (overlapping mechanics, role death mid-resolution, difficulty-tier differences) — not broad happy-path coverage. Happy-path is covered by the headless dry-run mode.

## Template

```
Test Case ID: BOSS#-MECH#-TC##
Title: [short description of the condition being tested]
Encounter: [boss name]
Mechanic: [name / ref to encounter spec section]
Role(s) involved: [role(s)]
Difficulty tier: [tier]

Preconditions:
- [state required before the test starts]

Steps:
1. [action]
2. [action]

Expected result:
- [what should happen, referencing the encounter spec's acceptance criteria]

Actual result: [filled in during test]
Pass/Fail: [ ]
Severity if failed: [Blocker / Major / Minor / Cosmetic]
Notes / repro details:
Linked commit or build:
```

## Conventions

- ID scheme: `BOSS#-MECH#-TC##`, tied directly to the encounter spec section it verifies.
- One test case = one specific condition.
- Each encounter spec's acceptance criteria should seed the initial list of test case titles for that encounter.
