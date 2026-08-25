# Boss 01: Kroll the Bulwark

Status: Draft v0.1
Last updated: 2026-08-25

Placeholder name — rename freely, nothing downstream depends on it. This is the v1 vertical-slice boss: one fully-tuned difficulty tier, 4 mechanics, all 5 playable archetypes covered.

---

## 0. Assumptions (flag if wrong)

- **Raid comp beyond the 5 playable seats:** this fight needs at least 2 tank seats (for the swap) and normally-sized healer/DPS contingents. Resolved per [`docs/architecture/encounter-data-schema.md`](../architecture/encounter-data-schema.md) §2: seats are drawn from an open-ended list of `KitDefinition`s under 4 role categories (Tank/Healer/DPS/Support-Puzzle), not a fixed enum — v1 has 5 player-eligible kits plus AI-only filler kits (`generic_tank`, `generic_healer`, `generic_dps`) to round out the comp. More unique Tank/Healer kits can be added later without changing this fight's data.
- **Single phase, HP-agnostic:** no phase transitions. All 4 mechanics run on repeating timers for the whole fight. Enrage is a hard timer, not an HP checkpoint.
- **Roster size stays a config value:** all group counts below are formulas over `roster_size`, never hardcoded to 25.

---

## 1. Overview

A melee bruiser boss. Auto-attacks stack a debuff on the current tank that forces a swap; the swap hands the healer a burst-healing check; meanwhile the raid must repeatedly split into soak groups, and one raid member at a time is periodically forced to run out of the group before a personal detonation goes off. Difficulty comes from the four timers drifting in and out of overlap.

**Enrage / encounter length:** 6:00 hard enrage (wipe if boss still alive).

---

## 2. Roles & Assignment Summary

| Seat | Mechanic(s) owned |
|---|---|
| Tank | #1 Marked for Ruin (swap timing) |
| Healer | #4 Festering Wound (post-swap focus heal) |
| DPS — Rotation | #3 Volatile Rupture (shared pool w/ DPS-Exotic, Support/Puzzle) |
| DPS — Exotic/Minigame | #3 Volatile Rupture (shared pool) |
| Support / Puzzle | #2 Overflowing Wrath (soak routing) + shares #3 pool |

Every seat also physically participates in the raid-wide soak (#2) unless they're currently the one running out for #3. This intentional overlap (soak window landing on top of a run-away assignment) is the main source of difficulty-tier tuning and should be a priority manual/edge-case test per `docs/testing/README.md`.

---

## 3. Mechanics

### #1 — Marked for Ruin (Tank Swap)

- **Trigger:** passive — every boss auto-attack (~1.5s cadence) on the current main tank.
- **Assigned responder:** Tank seat (both the active MT and the AI off-tank; if the player is Tank, they occupy whichever of the two the encounter puts them in).
- **Effect:** 1 stack per hit. At 4 stacks, the boss's next hit on that tank is a lethal-scale spike.
- **Resolution:** off-tank must taunt before the current tank reaches 4 stacks. Stacks on the outgoing tank decay 1 per 4s once they're no longer being hit, so they're tauntable again later.
- **Failure condition/consequence:** tank hits 4 stacks without a swap → tank takes near-lethal spike damage (likely death without an external cooldown, which v1 does not assume).

### #2 — Overflowing Wrath (Soak)

- **Trigger:** timer, every 25s.
- **Assigned responder:** Support/Puzzle seat owns *calling/routing* (deciding and communicating which spots are valid this cast); the whole raid is the physical responder for standing in a spot. Authored as two linked mechanic entries sharing one timer (schema doc §6) — not one mechanic with two responders.
- **Effect:** raid must split into `ceil(roster_size / 5)` groups of ~5, each standing in a designated soak zone, splitting incoming damage evenly within the group.
- **Resolution:** every group has enough people in it at cast resolution; nobody solos a zone; nobody stands unsoaked.
- **Failure condition/consequence:** under-filled or empty zone → unsplit damage hits at full value to whoever's there (or raid-wide damage if a zone is empty).

### #3 — Volatile Rupture (Run Away)

- **Trigger:** timer, every 30s (offset ~12s from the soak timer so it drifts in and out of overlap with #2 over the course of the fight — this drift is deliberate, not a bug).
- **Assigned responder:** one random seat from the pool {DPS-Rotation, DPS-Exotic, Healer, Support/Puzzle} — never a currently-tanking seat.
- **Effect:** targeted seat gets a detonation debuff with a 6s fuse.
- **Resolution:** targeted seat must clear a 15m radius from the rest of the raid before the fuse ends.
- **Failure condition/consequence:** fuse ends with anyone else inside 15m of the target → detonation damage hits everyone caught in radius (not just the carrier).

### #4 — Festering Wound (Focus Heal)

- **Trigger:** fires automatically whenever a tank swap resolves (i.e., #1 converts into this on swap) — the outgoing tank's 3+ stacks convert into this DoT rather than being wasted.
- **Assigned responder:** Healer seat.
- **Effect:** stacking DoT on the just-swapped-off tank, ~8s duration, damage-per-tick scales with how many stacks it converted from.
- **Resolution:** healer must land enough single-target healing on that specific tank during the window (on top of normal raid healing) to keep them above the death floor.
- **Failure condition/consequence:** insufficient focus healing → the tank dies from the DoT.

---

## 4. Difficulty Tier (v1's one tuned tier)

All numbers above are this tier's tuning. The data schema should carry these as tier-scoped values (cadence, stack thresholds, fuse duration, group size) even though v1 only ships one tier — per the design doc, tiers scale mechanic count/window tightness/punishment severity, in that order, and the data structure should already support that even though only this one tier is tuned now.

---

## 5. Acceptance Criteria

Testable, and the seed list for `docs/testing/boss-01.md`:

1. Boss data file expresses all 4 mechanics above via the (not-yet-written) mechanic schema, each with trigger, assigned_responder, resolution condition, and failure condition/consequence populated.
2. Headless dry-run (all seats AI-controlled, default roster size) completes the full 6:00 without any mechanic failure, across repeated runs.
3. In dry-run: off-tank always taunts before the active tank reaches 4 Marked for Ruin stacks.
4. In dry-run: every Overflowing Wrath cast resolves with all groups correctly filled at `ceil(roster_size/5)` groups of ~5.
5. In dry-run: every Volatile Rupture target clears 15m before the 6s fuse expires.
6. In dry-run: every Festering Wound instance is healed above the death floor before expiry.
7. Manual test: player occupying each of the 5 seats can individually fail their owned mechanic, and the specified failure consequence fires correctly (no silent no-op) — see design doc §10 on edge-case priority (overlapping mechanics, esp. #2/#3 collision).
8. Manual test: soak-window/run-away-window overlap (per the ~12s timer offset) is reachable and produces the expected simultaneous-demand scenario at least once per full encounter length.

---

## 6. Open Questions

- Exact death-floor / damage numbers for Festering Wound and Marked for Ruin's spike are placeholders pending actual HP/healing-throughput baselines, which don't exist yet since no character kits are implemented. Treat as first-pass, expect a tuning pass once kits exist.
