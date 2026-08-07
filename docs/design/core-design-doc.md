# [Working Title] — Core Design Document

Status: Draft v0.1
Last updated: 2026-08-07

---

## 1. Vision

A solo-player raid boss simulator. The player is one seat in a full raid — the other seats are AI-controlled and reliably competent. The player's individual decisions and execution determine whether the raid clears or wipes the boss, even though only 1 of the raid's seats is human-controlled.

**The fantasy:** the challenge and novelty of high-end raid encounter design, on demand, without the social/coordination overhead of a real guild. Raid whenever you want, at whatever seat you want, and the difficulty of the *encounter* is the obstacle — not other people.

**What this game is not:** it is not co-op, not a guild simulator, and (for v1) not a game about compensating for AI teammates' mistakes. The other 24 seats are assumed to play correctly; the challenge lives entirely in the mechanics and in the player's seat.

---

## 2. Design Pillars

1. **Any seat is a legitimate way to experience the fight.** A given boss encounter should be replayable and interesting whether the player is tanking, healing, doing rotation DPS, or playing an exotic/support seat. This is the core replayability engine, not a side feature.
2. **Break the trinity.** DPS/heal/tank is the baseline, not the ceiling. At least one playable seat per encounter should have no analog to damage or healing output — success is measured differently (e.g., mechanics resolved correctly).
3. **Player decisions are causally load-bearing.** Every mechanic has at least one piece specifically assigned to the player's seat. The player can win the fight through good play and can wipe the raid through bad play, regardless of which seat they're in.
4. **Kits can break the "cast bar" mold.** A DPS seat doesn't have to mean priority-list ability rotation. Damage/healing/utility output can be gated behind other input types (minigames, puzzles, precision execution) while the player still tracks and responds to boss mechanics in real time.
5. **Punishing, not unfair.** Difficulty comes from tighter windows, more simultaneous mechanics, and less margin for error — not from hidden information or AI teammates behaving randomly.

---

## 3. Roles / Seats

Long-term target: a large simulated raid (roster size is a config value, not a hardcoded constant — see §8) with many playable seat archetypes. **V1 scope is 5 representative archetypes**, chosen to prove the pillars above with the smallest viable set.

### 3.1 Tank (baseline trinity seat)
Traditional core loop: positioning, mitigation cooldown timing, threat/aggro management on adds.
V1 scope: single-target tanking with basic cooldown management.
**Noted for post-v1 expansion:** side-tanking, taunt swapping, kiting, multi-target threat juggling — legitimate depth, deliberately deferred so v1 stays small.

### 3.2 Healer (baseline trinity seat)
Traditional core loop: resource-limited throughput against incoming damage patterns, cooldown timing against known burst windows.

### 3.3 DPS — Rotation (baseline trinity seat, likely a single character)
Plays like a familiar MMO caster/melee kit: priority-based ability sequencing, procs, cooldown windows. This is the "reassurance" seat — proves the game respects the genre it's drawing from.
**Design note:** unlike Tank/Healer, "DPS" is not meant to be a single generic archetype — each DPS character should have a genuinely unique kit (see §3.4 for one example). This rotation-based kit will most likely be exactly one specific character among several DPS characters, not a category multiple characters share. Additional DPS kit concepts beyond this one and the exotic/minigame one are expected post-v1.

### 3.4 DPS — Exotic / Minigame-driven (trinity-breaking, primary differentiator)
Passive low damage floor from basic actions. Large damage windows are gated behind a short, high-focus minigame (rhythm/pattern/aim-based) triggered on its own cooldown, executed *while* boss mechanics continue to demand attention. The core tension is split-attention execution, not resource management.
**Design note:** this is the seat most worth iterating on and playtesting early — it's the least-proven mechanic in the genre.

### 3.5 Support / Puzzle (trinity-breaking, clearest trinity break)
No damage or healing output. Contribution is a spatial or logical puzzle tied to the fight (routing a hazard, sequencing switches, redirecting an effect) that prevents a wipe mechanic or empowers the rest of the raid. Success is measured in mechanics correctly resolved, not DPS/HPS.

---

## 4. AI Teammate Model

24 (or roster size − 1) seats are AI-controlled.

- **v1 assumption: near-flawless execution.** AI teammates correctly perform their role and correctly resolve any mechanic assigned to their seat. They are not a source of failure.
- **Consequence:** the player only ever fails because of their own seat's execution or decisions. This keeps encounter design and AI design tractable for v1.
- **Post-v1 hook (not built in v1, but architected for):** each mechanic's data definition includes an `assigned_responder` field. In v1 this always resolves successfully for AI-controlled seats. A future "AI mistake compensation" mode could allow assigned AI responders to occasionally fail, requiring the player to detect and cover the gap. Keeping this as a data-level toggle rather than hardcoding flawless behavior avoids an architecture rewrite later.

---

## 5. Encounters

- A raid tier consists of 8–11 bosses (long-term target). **V1 scope: 1 boss.**
- Bosses are defined as data (not one-off code per fight) — see architecture doc for schema. This is a hard requirement: it's what keeps adding content tractable and what lets Claude Code implement new bosses against a predictable format instead of bespoke logic each time.
- Each boss has a set of mechanics. Each mechanic has:
  - A trigger condition (timer, HP threshold, etc.)
  - An assigned responder (which seat/role must act)
  - A resolution condition (what "handled correctly" means)
  - A failure condition and consequence (what happens if unresolved)
- Every encounter must have at least one mechanic assigned to whichever seat the player occupies, regardless of which of the 5 (eventually more) archetypes that is.

---

## 6. Difficulty Tiers

Difficulty scaling primarily affects, in increasing order of aggressiveness:
1. Number of concurrent mechanics
2. Tightness of response windows
3. Punishment severity for missed/late resolution
4. (Post-v1) introduction of the AI-mistake-compensation layer

V1 scope: implement the data structure to support tiers, but only fully tune **one** difficulty tier end-to-end. Additional tiers are a content/tuning task once the base loop is validated, not a v1 architectural requirement.

---

## 7. Scoring / "Perfect Run" System

Goal: give every role a meaningful way to measure and push their own performance, analogous to WoW parsing — but role-appropriate rather than DPS/HPS-only, since that measure is a poor fit for non-damage roles (this was one of the explicit problems with WoW's system that this game should avoid repeating).

Each role gets its own scoring dimensions. Sketch (to be refined per-role during implementation):
- **Tank:** mitigation efficiency, uptime on assigned targets, cooldown usage timing.
- **Healer:** throughput efficiency relative to damage taken, cooldown timing against known burst windows, overhealing minimized.
- **DPS (rotation):** traditional throughput/parse-style score.
- **DPS (exotic):** minigame execution accuracy/score, damage window uptime.
- **Support/puzzle:** mechanics resolved correctly, time-to-resolution, errors made.

A "perfect run" is defined per-role, per-boss, per-difficulty-tier as a named target (not just a numeric high score) so it can be surfaced as a concrete goal ("no mitigation cooldown wasted, zero mechanic failures") rather than an abstract leaderboard number.

---

## 8. Roster Size

Not locked for v1. Treated as a config value in the boss/encounter data, not hardcoded — deferring the 10/15/25 decision has no architectural cost as long as agent management is written to scale with a variable count rather than assuming a fixed 24.

---

## 9. Tooling & Debug Requirements

Built alongside v1 (not deferred), because agent+mechanic timing bugs are otherwise very hard to diagnose:

- **Agent state overlay** — toggleable panel showing each AI seat's current action, target, cooldowns, resources, health, and assigned mechanic (if any).
- **Decision logging** — log which rule/priority fired for each AI action taken.
- **Headless dry-run mode** — simulate a full encounter with all seats AI-controlled (including the player's normal seat); report completion, duration, and any mechanic that failed to trigger or resolved incorrectly. Serves as an automated regression test for encounter design.

Deferred until after the base loop is validated, added before scaling to more content:

- **Deterministic replay** — seeded RNG + recorded input/event stream for exact bug reproduction.
- **Pause/step/slow-motion controls** — trivial in Godot via time scale; high value for tuning tight timing windows.
- **Invariant assertions** — lightweight runtime checks for impossible states (negative resources, no valid target, wipe condition not firing when it should).

---

## 10. Testing Approach

Manual testing is the primary validation method for correctness and feel; the headless dry-run mode is the automated smoke test for happy-path regressions.

- Test cases are written per-mechanic, not per-boss, using the format defined in `/docs/testing/README.md`.
- Each encounter spec's acceptance criteria (see §11) double as the seed list of test case titles.
- Edge cases prioritized in manual testing: overlapping mechanics, role death mid-resolution, difficulty-tier behavioral differences — cases a script is unlikely to catch.

---

## 11. Documentation Structure

```
/docs
  design/            — this doc, and other cross-cutting design docs
  architecture/       — technical system docs (agent AI, mechanic resolution, data schema)
  encounters/         — one spec per boss: mechanic list, role assignments, timing, acceptance criteria
  testing/            — one test case file per encounter, format per README
/godot-project
/tools
CLAUDE.md
CHANGELOG.md
```

Each encounter spec must include explicit acceptance criteria (what "correctly implemented" means, testable) — this is what both the headless dry-run and manual test cases check against.

---

## 12. V1 Scope Summary

- 1 boss
- 5 archetypes: Tank, Healer, DPS (Rotation), DPS (Exotic/Minigame), Support/Puzzle
- 1 fully-tuned difficulty tier (data structure supports more, not required to build more)
- Full/near-flawless AI teammates (no mistake-compensation layer)
- Godot, full 3D, simplified camera (fixed or orbit-follow, not free camera) and low-poly/simple assets — visual fidelity is a post-v1 concern
- Debug tooling: state overlay, decision logging, headless dry-run built alongside
- Manual test cases written per-mechanic alongside each encounter spec

## 13. Explicitly Deferred (post-v1)

- Roster size beyond config default
- Tank depth (side-tanking, taunt swaps, kiting)
- AI-mistake-compensation gameplay layer
- Additional difficulty tiers
- Additional archetypes / seats
- Replay, step controls, invariant assertions
- Visual/animation polish
