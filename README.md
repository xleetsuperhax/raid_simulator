# [Working Title]

A solo-player raid boss simulator. Full design context in `docs/design/core-design-doc.md`. Claude Code should read `CLAUDE.md` before making changes.

## Status

Pre-implementation. Design doc drafted (v0.1). Next: first encounter spec, then implementation of the vertical slice (1 boss, 5 character kits, 1 difficulty tier).

## Structure

```
/docs/design/        — design doc + cross-cutting design decisions
/docs/architecture/   — technical system docs
/docs/encounters/     — per-boss specs (mechanics, role assignments, acceptance criteria)
/docs/testing/        — per-encounter manual test cases
/godot-project/        — the Godot project
/tools/                — supporting scripts (e.g. validation, asset pipeline)
```
