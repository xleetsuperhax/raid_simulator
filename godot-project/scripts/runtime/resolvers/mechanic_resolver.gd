class_name MechanicResolver
extends RefCounted

## Contract every resolver_id maps to (docs/architecture/encounter-data-schema.md §5).
## `runtime` is deliberately untyped here to avoid a script-cycle with EncounterRuntime,
## which itself references resolver classes by name.

## Called the instant the mechanic's trigger fires. Selects responder(s) and
## records whatever this resolver needs in the returned instance's `data`.
func on_trigger(mechanic: MechanicDefinition, runtime) -> MechanicInstance:
	return MechanicInstance.new(mechanic, 0.0)

## Called immediately after on_trigger. v1 rule (design doc §4): AI-controlled
## responders always resolve correctly — a resolver should only return false
## for a genuine data-level failure (e.g. no eligible responder existed), never
## to simulate an AI mistake.
func resolve(_instance: MechanicInstance, runtime) -> bool:
	return true
