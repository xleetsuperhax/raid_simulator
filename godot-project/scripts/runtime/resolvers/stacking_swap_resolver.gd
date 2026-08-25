class_name StackingSwapResolver
extends MechanicResolver

## resolver_id "stacking_swap" — e.g. marked_for_ruin. Stacks build on the
## current active-role responder (the active tank); the off-responder swaps
## in one hit before the stack threshold would be reached. If the off-tank is
## player-controlled, this resolver does NOT auto-swap them — it only checks
## whether EncounterRuntime.player_taunt() already happened. Design doc §4:
## AI-controlled responders always resolve correctly; player-controlled ones
## depend on real input.

func on_trigger(mechanic: MechanicDefinition, runtime) -> MechanicInstance:
	var instance := MechanicInstance.new(mechanic, runtime.time)
	var active_tank: SeatState = runtime.get_active_tank()
	if active_tank == null:
		instance.data["error"] = "no_active_tank"
		return instance
	var stacks: int = int(active_tank.stacks.get(mechanic.id, 0)) + 1
	active_tank.stacks[mechanic.id] = stacks
	active_tank.current_mechanic_id = mechanic.id
	instance.data["hit_seat_index"] = active_tank.index
	instance.data["stacks"] = stacks
	return instance

func resolve(instance: MechanicInstance, runtime) -> bool:
	var mechanic := instance.mechanic
	if instance.data.get("error") != null:
		instance.data["chain_event"] = false
		return false

	var threshold: int = int(mechanic.params.get("stack_threshold", 4))
	var stacks: int = int(instance.data["stacks"])
	var active_tank: SeatState = runtime.seats[instance.data["hit_seat_index"]]

	if stacks >= threshold:
		# Reached the lethal-scale hit without a swap — genuine failure.
		instance.data["chain_event"] = false
		return false

	if stacks != threshold - 1:
		# Below the swap point yet; nothing to resolve on this hit.
		instance.data["chain_event"] = false
		return true

	var off_tank: SeatState = runtime.get_inactive_tank()
	if off_tank == null:
		instance.data["chain_event"] = false
		return false

	if off_tank.is_player:
		# Nothing to auto-resolve — the player must call player_taunt()
		# themselves. Not doing so before the next hit is a real failure,
		# handled by the `stacks >= threshold` branch above on that hit.
		instance.data["chain_event"] = false
		return true

	instance.data["outgoing_tank_seat_index"] = active_tank.index
	instance.data["stacks_at_swap"] = stacks
	active_tank.active_tank = false
	active_tank.stacks[mechanic.id] = 0
	off_tank.active_tank = true
	off_tank.current_mechanic_id = mechanic.id
	runtime.decision_log.log(runtime.time, off_tank.index, mechanic.id, "ai_off_tank_taunt_swap", "resolved")
	instance.data["chain_event"] = true
	return true
