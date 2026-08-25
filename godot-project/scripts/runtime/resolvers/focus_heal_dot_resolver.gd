class_name FocusHealDotResolver
extends MechanicResolver

## resolver_id "focus_heal_dot" — e.g. festering_wound. Chains off another
## mechanic's "resolved" event (source_mechanic_id/source_event on the
## trigger) and requires the Healer responder(s) to keep the DoT'd target
## above a death floor.

func on_trigger(mechanic: MechanicDefinition, runtime) -> MechanicInstance:
	var instance := MechanicInstance.new(mechanic, runtime.time)
	var source: MechanicInstance = runtime.last_instance.get(mechanic.trigger.source_mechanic_id)
	if source == null or not source.data.has("outgoing_tank_seat_index"):
		instance.data["error"] = "no_source_swap_data"
		return instance
	instance.data["target_seat_index"] = source.data["outgoing_tank_seat_index"]
	instance.data["stacks_converted"] = source.data.get("stacks_at_swap", 0)
	return instance

func resolve(instance: MechanicInstance, runtime) -> bool:
	if instance.data.get("error") != null:
		return false

	var mechanic := instance.mechanic
	var target: SeatState = runtime.seats[instance.data["target_seat_index"]]
	var death_floor: float = float(mechanic.params.get("death_floor_fraction", 0.15))
	# Placeholder damage model — no real HP/healing-throughput numbers exist
	# yet (no kits implemented). This just needs to visibly dip and recover
	# for the overlay/log; see boss-01.md §6 open questions for the real pass.
	target.hp_fraction = max(death_floor, min(1.0, target.hp_fraction - 0.2))
	target.current_mechanic_id = mechanic.id

	var healers: Array = runtime.select_responders(mechanic.responder)
	var healer_index := -1
	if not healers.is_empty():
		healer_index = healers[0].index
	runtime.decision_log.log(runtime.time, healer_index, mechanic.id,
		"ai_focus_heal_target_%d" % target.index, "resolved")
	return true
