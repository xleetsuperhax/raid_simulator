# CLAUDE.md

Context file for Claude Code sessions on this project. Read this before making changes.

## What this project is

A solo-player raid boss simulator (WoW-inspired). The player occupies one seat in a full raid; the other seats are AI-controlled and near-flawless in v1. Full design context: `docs/design/core-design-doc.md` — read it before implementing anything that touches game design, roles, or encounters.

## Current scope (v1)

1 boss, 5 playable character kits (Tank, Healer, DPS-Rotation, DPS-Exotic/Minigame, Support/Puzzle), 1 fully-tuned difficulty tier, near-flawless AI teammates. Full scope summary: `docs/design/core-design-doc.md` §12–13. Do not build features listed under §13 (Explicitly Deferred) unless the user asks — they are intentionally out of scope for now.

## Engine & stack

- Godot 4.x, GDScript
- Full 3D, but v1 uses simplified camera (fixed or orbit-follow, not free camera) and simple/low-poly assets. Visual fidelity is a post-v1 concern — do not over-invest in it.

## Architecture principles

- **Encounters, mechanics, and character kits are data-driven** (Godot Resources or JSON), not hardcoded per-boss/per-kit scripts. Adding a mechanic to a boss should be a data-entry task following a defined schema, not new bespoke code. If a schema doesn't exist yet for something, propose one and confirm before hardcoding a one-off.
- Each mechanic's data definition includes an `assigned_responder` field (which seat must act) and a resolution/failure condition. In v1, AI-assigned responders always resolve successfully — do not build in random AI failure; that's an explicitly deferred feature (see design doc §4).
- Roster size (number of simulated seats) is a config value, not a hardcoded constant.

## Required tooling (build alongside features, not after)

- **Agent state overlay**: toggle-able panel showing each AI seat's action, target, cooldowns, resources, health, assigned mechanic.
- **Decision logging**: log which rule fired for each AI action.
- **Headless dry-run mode**: simulate a full encounter with all 25 (or configured roster size) seats AI-controlled, report completion/duration/mechanic failures. This is the automated regression test — run it after changes that touch encounter or agent logic.

Deferred (do not build without being asked): deterministic replay, pause/step/slow-motion, invariant assertions.

## Docs structure

```
/docs/design/        — core design doc + cross-cutting design docs
/docs/architecture/   — technical system docs (agent AI, mechanic resolution, data schema)
/docs/encounters/     — one spec per boss: mechanics, role assignments, timing, acceptance criteria
/docs/testing/        — one test case file per encounter, format in docs/testing/README.md
```

When implementing a boss or mechanic, look for its spec under `docs/encounters/` first. If no spec exists yet, ask rather than inventing encounter design — encounter design decisions belong in the design doc / encounter spec, not in code.

## Testing

Manual testing is the primary validation method (see `docs/testing/README.md` for test case format); the headless dry-run is the automated smoke test. When implementing a mechanic, check whether its encounter spec has acceptance criteria and treat those as the definition of done.

## Conventions

- One mechanic or one role feature per commit, referencing the doc section it implements (e.g. `Implement Tank taunt mechanic (encounters/boss-01.md #mechanic-2)`).
- GDScript style: [fill in once established — e.g. static typing preferred, snake_case for functions/variables, PascalCase for classes/nodes].
- Ask before introducing new third-party addons/plugins.

## What not to do

- Don't add roster-size-25 assumptions hardcoded anywhere — it's a config value.
- Don't build AI-mistake/compensation behavior, additional difficulty tiers beyond the one being tuned, or additional character kits beyond v1 scope without explicit confirmation.
- Don't invest in visual/animation polish before the base loop (one boss, five kits, one difficulty tier) is functionally complete.
