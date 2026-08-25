class_name FleeDetonationResolver
extends MechanicResolver

## resolver_id "flee_detonation" — e.g. volatile_rupture. One randomly-chosen
## responder (excluding the current tank, per the mechanic's exclusion rule)
## must clear a radius before a fuse expires.

func on_trigger(mechanic: MechanicDefinition, runtime) -> MechanicInstance:
	var instance := MechanicInstance.new(mechanic, runtime.time)
	var responders: Array = runtime.select_responders(mechanic.responder)
	if responders.is_empty():
		instance.data["error"] = "no_eligible_target"
		return instance
	var target: SeatState = responders[0]
	target.current_mechanic_id = mechanic.id
	instance.data["target_seat_index"] = target.index
	return instance

func resolve(instance: MechanicInstance, runtime) -> bool:
	if instance.data.get("error") != null:
		return false
	var target: SeatState = runtime.seats[instance.data["target_seat_index"]]
	runtime.decision_log.log(runtime.time, target.index, instance.mechanic.id, "ai_flee_clear_radius", "resolved")
	return true
