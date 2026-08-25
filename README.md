# [Working Title]

A solo-player raid boss simulator. Full design context in `docs/design/core-design-doc.md`. Claude Code should read `CLAUDE.md` before making changes.

## Status

Design doc drafted (v0.1). First encounter spec (`docs/encounters/boss-01.md`) and the encounter/mechanic data schema (`docs/architecture/encounter-data-schema.md`) are written. Godot project scaffolded with the schema implemented as Resource classes (`godot-project/scripts/data/`) and boss-01's data authored (`godot-project/resources/`).

A minimal mechanic-resolution runtime now drives boss-01 end to end with all seats AI-controlled (`godot-project/scripts/runtime/`), backing the three required debug tools: an agent state overlay (F1, `godot-project/scripts/ui/`), decision logging, and a headless dry-run (`godot-project/scripts/dry_run/dry_run_cli.gd` — run after any change touching encounter/agent logic). `scenes/main.tscn` now also renders a minimal 3D arena view (`godot-project/scripts/visual/arena_view.gd`) — boss marker plus a ring of role-colored seat markers, active tank visibly distinct.

Two of the five v1 seats are playable. Press **1** or **2** at launch to pick one:

- **Tank** — WASD move, T taunt. Taunting is wired directly into the marked_for_ruin mechanic's resolution, so miss the window and the mechanic genuinely fails (design doc §4's "player can wipe the raid through bad play," now real, not just written down).
- **DPS-Exotic** (design doc §3.4) — WASD move, R to start a rhythm minigame once its cooldown is up. Notes actually fall down a lane (`godot-project/scripts/ui/rhythm_lane.gd`) toward a marked hit-zone; press SPACE when one arrives. 4+ of 5 hits lands a big damage window; a passive low floor ticks regardless. Runs on the same clock as the boss's mechanic timers, so committing to the minigame while, say, a run-away mechanic is about to target you is a real trade-off — though that particular mechanic (Volatile Rupture) doesn't yet have a real fail state for a player-controlled target (flagged in code, not fixed yet).

Still no kit resource/cooldown systems beyond these two specific mechanics, no camera-relative movement (WASD is world-space — the follow camera doesn't rotate with input), and no proper seat-select menu (it's a one-line keypress, fine for two kits, worth a real menu once there's a third).

## Structure

```
/docs/design/        — design doc + cross-cutting design decisions
/docs/architecture/   — technical system docs
/docs/encounters/     — per-boss specs (mechanics, role assignments, acceptance criteria)
/docs/testing/        — per-encounter manual test cases
/godot-project/        — the Godot project
/tools/                — supporting scripts (e.g. validation, asset pipeline)
```
