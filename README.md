# [Working Title]

A solo-player raid boss simulator. Full design context in `docs/design/core-design-doc.md`. Claude Code should read `CLAUDE.md` before making changes.

## Status

Design doc drafted (v0.1). First encounter spec (`docs/encounters/boss-01.md`) and the encounter/mechanic data schema (`docs/architecture/encounter-data-schema.md`) are written. Godot project scaffolded with the schema implemented as Resource classes (`godot-project/scripts/data/`) and boss-01's data authored (`godot-project/resources/`).

A minimal mechanic-resolution runtime now drives boss-01 end to end with all seats AI-controlled (`godot-project/scripts/runtime/`), backing the three required debug tools: an agent state overlay (F1, `godot-project/scripts/ui/`), decision logging, and a headless dry-run (`godot-project/scripts/dry_run/dry_run_cli.gd` — run after any change touching encounter/agent logic). No player input, kits, or damage numbers yet — those are next.

## Structure

```
/docs/design/        — design doc + cross-cutting design decisions
/docs/architecture/   — technical system docs
/docs/encounters/     — per-boss specs (mechanics, role assignments, acceptance criteria)
/docs/testing/        — per-encounter manual test cases
/godot-project/        — the Godot project
/tools/                — supporting scripts (e.g. validation, asset pipeline)
```
