# Encounter & Mechanic Data Schema

Status: Draft v0.1
Last updated: 2026-08-25

Defines how bosses/mechanics are authored as data rather than per-boss code (design doc §5, a hard requirement). Written against [`docs/encounters/boss-01.md`](../encounters/boss-01.md) — every field below exists because boss-01 needs it, not speculatively. Extend this schema when the *next* boss needs something new, not before.

---

## 1. Format: Godot Resources, not JSON

Design doc allows either. Picking custom `Resource` subclasses (`.tres`, authored via the Inspector) over JSON:

- Inspector editing + typed fields catch authoring mistakes (wrong enum value, missing field) at edit time, not at runtime.
- Resources can reference other Resources directly (a mechanic referencing a resolver, a tier referencing overrides) without a hand-rolled loader/parser.
- No JSON round-trip layer to write and maintain for a solo-dev project.

Revisit only if external (non-Godot) tooling for authoring encounters becomes a real need — not before.

---

## 2. Seats & Roster Composition — Kits, not a fixed seat enum

**Resolved (was open in v0.1):** the user wants unique Tank/Healer kits added later too, not just DPS (design doc §3.3 already says DPS gets multiple unique kits post-v1). So seat taxonomy can't be a closed enum of "5 named + 3 generic" — kits are an open, data-defined list under 4 broad role categories, and "generic filler" is just an ordinary (non-unique, AI-only) kit like any other:

```gdscript
class_name GameEnums
extends RefCounted

enum RoleCategory { TANK, HEALER, DPS, SUPPORT_PUZZLE }
```

```gdscript
class_name KitDefinition
extends Resource

@export var id: String            # e.g. "tank", "generic_tank", "dps_exotic" — stable, referenced by save data etc.
@export var display_name: String
@export var role_category: GameEnums.RoleCategory
@export var player_eligible: bool # true for the 5 v1 kits; false for AI-only filler kits
```

v1 defines 5 player-eligible kits (Tank, Healer, DPS-Rotation, DPS-Exotic, Support/Puzzle) plus as many AI-only filler kits (`generic_tank`, `generic_healer`, `generic_dps`) as a given encounter's comp needs. Adding a second unique Tank kit later is just adding another `KitDefinition` with `role_category = TANK, player_eligible = true` — no schema change.

```gdscript
class_name RaidComposition
extends Resource

@export var roster_size: int = 25
@export var kit_counts: Dictionary  # kit id (String) -> count (int); must sum to roster_size, validated on load
```

Kits are referenced by `id` (string), not a direct Resource pointer, resolved at load time against a small kit registry (a Dictionary of `id -> KitDefinition` built from everything under `res://resources/kits/`). Simpler than a typed array of allocation-pair resources for the same result, and keeps authoring a composition down to editing a plain dictionary.

Every `EncounterDefinition` references one `RaidComposition`. Changing `roster_size` in one place is what "roster size is a config value" (design doc §8) means in practice. Mechanics never reference a specific kit — they reference `RoleCategory` (§3.2), so a mechanic like "tank swap" automatically includes any future second Tank kit without being edited.

---

## 3. Mechanic Definition

```gdscript
class_name MechanicDefinition
extends Resource

@export var id: String                  # e.g. "marked_for_ruin"
@export var display_name: String
@export var trigger: TriggerDefinition
@export var responder: ResponderDefinition
@export var resolver_id: String          # which resolver archetype checks this mechanic — see §5
@export var params: Dictionary           # tunable numbers the resolver reads, e.g. {"stack_threshold": 4}
@export var failure_consequence: String  # short id, e.g. "tank_lethal_spike" — resolved by the effect/damage system, not this schema
```

`params` is a loose `Dictionary` rather than a typed field per mechanic, because every mechanic archetype needs different numbers (stack thresholds vs. group sizes vs. fuse durations) and typed subclass-per-mechanic would just be boss-01's 4 shapes hardcoded into the schema itself. The resolver (§5) is the thing that knows what keys it expects — document that contract per resolver, not per schema field.

### 3.1 Trigger

```gdscript
class_name TriggerDefinition
extends Resource

enum Type { TIMER, ON_HIT, ON_MECHANIC_EVENT }

@export var type: Type
# TIMER
@export var interval_seconds: float = 0.0
@export var offset_seconds: float = 0.0     # boss-01 uses this to keep #2/#3 drifting in/out of phase
# ON_HIT
@export var hit_target_responder: bool = true  # fires when the boss hits whoever holds the responder role
# ON_MECHANIC_EVENT
@export var source_mechanic_id: String = ""
@export var source_event: String = ""       # e.g. "resolved" — Festering Wound listens for Marked for Ruin's swap resolution
```

Three trigger shapes cover all 4 boss-01 mechanics (timer, on-hit, chained-off-another-mechanic). Don't add a fourth until a boss actually needs one.

`interval_seconds` is reused for `ON_HIT` as the attack cadence landing on the responder (e.g. marked_for_ruin's boss auto-attack every 1.5s) rather than adding a second field — TIMER and ON_HIT both just mean "this fires again every N seconds," they differ only in what's counted as the responder.

### 3.2 Responder

```gdscript
class_name ResponderDefinition
extends Resource

enum Mode { BY_ROLE, WHOLE_RAID }
enum Selection { ALL_MATCHING, RANDOM_ONE }
enum Exclusion { NONE, NOT_CURRENT_TANK }

@export var mode: Mode
@export var role_categories: Array[GameEnums.RoleCategory]  # used when mode == BY_ROLE
@export var selection: Selection = Selection.ALL_MATCHING
@export var exclusion: Exclusion = Exclusion.NONE
```

`SEAT_KIND` and `POOL` from v0.1 collapsed into one `BY_ROLE` mode — the only real difference between them was `selection` (all matching vs. random one), which was already its own field.

- Marked for Ruin: `mode=BY_ROLE, role_categories=[TANK], selection=ALL_MATCHING` (both MT/OT participate).
- Overflowing Wrath: `mode=WHOLE_RAID` for the physical soak — routing is now its own mechanic entry, resolved per §7.
- Volatile Rupture: `mode=BY_ROLE, role_categories=[DPS, HEALER, SUPPORT_PUZZLE], selection=RANDOM_ONE, exclusion=NOT_CURRENT_TANK`.
- Festering Wound: `mode=BY_ROLE, role_categories=[HEALER]`.

---

## 4. Encounter & Difficulty Tier

```gdscript
class_name EncounterDefinition
extends Resource

@export var id: String
@export var display_name: String
@export var composition: RaidComposition
@export var enrage_seconds: float
@export var mechanics: Array[MechanicDefinition]
@export var tiers: Array[DifficultyTier]
```

```gdscript
class_name DifficultyTier
extends Resource

@export var id: String  # e.g. "normal" — v1 ships exactly one, per design doc §6
# sparse overrides: only list what this tier changes from the mechanic's base params
@export var param_overrides: Dictionary  # mechanic_id -> Dictionary (param_name -> value)
```

A tier is applied by shallow-merging its `param_overrides[mechanic_id]` over that mechanic's base `params` at encounter load. V1 has one tier with an empty/no-op override set — the mechanism exists per design doc §6, without a second tier to actually tune yet.

---

## 5. Resolver Contract

A **resolver** is the GDScript logic that knows how to check one *archetype* of mechanic — not one specific mechanic. Boss-01's 4 mechanics need exactly 4 resolver archetypes; future bosses should reuse these before adding a 5th.

| resolver_id | archetype | expects in `params` |
|---|---|---|
| `stacking_swap` | passive stack builds on a responder, another responder must relieve them before threshold | `stack_threshold`, `decay_per_tick`, `decay_interval_seconds` |
| `grouped_soak` | whole raid splits into N groups of a target size | `group_size` (roster splits into `ceil(roster_size / group_size)` groups) |
| `soak_router` | a single responder must call/assign valid soak spots each time the linked soak mechanic triggers | (no numeric params — correctness is "did it call routing before the soak resolves") |
| `flee_detonation` | one responder must clear a radius before a fuse expires | `fuse_seconds`, `clear_radius_m` |
| `focus_heal_dot` | responder must land enough single-target healing on a DoT'd target before it expires | `duration_seconds`, `death_floor_fraction` |

Each resolver script implements the same minimal interface so the dry-run harness and agent overlay can treat all mechanics uniformly:

```gdscript
# conceptual interface every resolver_id maps to
func on_trigger(mechanic: MechanicDefinition, context: EncounterContext) -> void
func check_resolution(mechanic: MechanicDefinition, context: EncounterContext) -> ResolutionResult
```

`ResolutionResult` (resolved / failed / pending) is what the headless dry-run mode (design doc §9) aggregates into its completion/duration/failure report, and what decision logging records for AI-driven resolutions.

**v1 AI resolution rule (design doc §4):** when the responder seat(s) for a given mechanic instance are AI-controlled, the resolver auto-resolves them correctly (e.g., AI off-tank always taunts in time) — this is scripted certainty, not a "very good AI" simulation. The resolver must still emit a decision-log line for *why* the AI acted (which rule fired) even though the outcome is fixed, since that's required tooling (design doc §9), and the agent overlay must be able to show that seat's current assigned mechanic regardless of AI-vs-player. Only player-occupied seats have resolution driven by actual gameplay input.

---

## 6. Worked Example: Marked for Ruin

Illustrative, not final field values (boss-01's numbers are still placeholders per its §6):

```
MechanicDefinition
  id: "marked_for_ruin"
  trigger:
    type: ON_HIT
    hit_target_responder: true
  responder:
    mode: BY_ROLE
    role_categories: [TANK]
    selection: ALL_MATCHING
  resolver_id: "stacking_swap"
  params: { stack_threshold: 4, decay_per_tick: 1, decay_interval_seconds: 4 }
  failure_consequence: "tank_lethal_spike"
```

Festering Wound then chains off it:

```
MechanicDefinition
  id: "festering_wound"
  trigger:
    type: ON_MECHANIC_EVENT
    source_mechanic_id: "marked_for_ruin"
    source_event: "resolved"
  responder:
    mode: BY_ROLE
    role_categories: [HEALER]
  resolver_id: "focus_heal_dot"
  params: { duration_seconds: 8, death_floor_fraction: 0.15 }
  failure_consequence: "tank_dot_death"
```

And Overflowing Wrath is two linked entries — physical soak plus routing:

```
MechanicDefinition
  id: "overflowing_wrath_soak"
  trigger:
    type: TIMER
    interval_seconds: 25
  responder:
    mode: WHOLE_RAID
  resolver_id: "grouped_soak"
  params: { group_size: 5 }
  failure_consequence: "soak_group_damage"

MechanicDefinition
  id: "overflowing_wrath_routing"
  trigger:
    type: ON_MECHANIC_EVENT
    source_mechanic_id: "overflowing_wrath_soak"
    source_event: "triggered"
  responder:
    mode: BY_ROLE
    role_categories: [SUPPORT_PUZZLE]
  resolver_id: "soak_router"
  params: {}
  failure_consequence: "soak_group_damage"
```

`ON_MECHANIC_EVENT.source_event` therefore has two values in use: `"triggered"` (fires the instant the source mechanic's trigger condition fires — used above so routing happens *before* the soak resolves) and `"resolved"` (fires only once the source mechanic's resolution is checked, as Festering Wound does off Marked for Ruin's swap). Both are needed by boss-01 as written, so both are in scope now rather than added speculatively.

---

## 7. Resolved Questions (from v0.1)

- **Seat taxonomy:** resolved via §2 — open-ended `KitDefinition` list under 4 `RoleCategory` values, not a fixed enum. Supports unique Tank/Healer kits later without a schema change.
- **Soak's split responder:** resolved — two separate `MechanicDefinition` entries sharing the same timer via `ON_MECHANIC_EVENT`/`"triggered"`, per §6 above.

## 8. Remaining Open Questions

- None outstanding — §9 below records how the questions in this doc were actually settled during implementation.

## 9. Implementation Notes (post-schema)

- Resolver scripts live under `godot-project/scripts/runtime/resolvers/`, one script per `resolver_id`, all extending `MechanicResolver`. `EncounterRuntime._build_resolvers()` is the fixed lookup from `resolver_id` string to resolver instance — a plain `Dictionary` literal, not a naming-convention scan, since the resolver set only grows when a new mechanic archetype is needed.
- `EncounterRuntime` (`godot-project/scripts/runtime/encounter_runtime.gd`) is the scheduler: it owns `seats: Array[SeatState]`, ticks `TIMER`/`ON_HIT` mechanics off a `timers` dictionary, and fires `ON_MECHANIC_EVENT` listeners synchronously off `"triggered"`/`"resolved"` events. `ResponderDefinition` resolution (role/whole-raid, selection, exclusion) is centralized in `EncounterRuntime.select_responders()` rather than duplicated per resolver.
- Mechanic `.tres` resources are loaded once and cached by the engine; the runtime never mutates them directly — `_apply_tier()` deep-`duplicate()`s each `MechanicDefinition` per encounter run before applying tier overrides.
- Player vs. AI resolution (design doc §4): `EncounterRuntime.setup()` takes an optional `player_kit_id` — the matching seat gets `SeatState.is_player = true`, everything else about it is identical to an AI seat. Resolvers branch on `is_player` to stop auto-resolving and instead wait for a real player action (see `StackingSwapResolver` — `EncounterRuntime.player_taunt()` is the first such action). Omitting `player_kit_id` (as the headless dry-run does) reproduces the old all-AI behavior exactly.
