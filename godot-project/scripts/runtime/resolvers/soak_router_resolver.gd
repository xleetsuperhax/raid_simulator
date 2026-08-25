class_name SoakRouterResolver
extends MechanicResolver

## resolver_id "soak_router" — e.g. overflowing_wrath_routing. Fires on its
## source soak mechanic's "triggered" event (before that mechanic resolves),
## representing Support/Puzzle calling valid soak spots for that cast.

func on_trigger(mechanic: MechanicDefinition, runtime) -> MechanicInstance:
	var instance := MechanicInstance.new(mechanic, runtime.time)
	var responders: Array = runtime.select_responders(mechanic.responder)
	var indices: Array = []
	for r in responders:
		r.current_mechanic_id = mechanic.id
		indices.append(r.index)
	instance.data["router_seat_indices"] = indices
	return instance

func resolve(instance: MechanicInstance, runtime) -> bool:
	var indices: Array = instance.data.get("router_seat_indices", [])
	if indices.is_empty():
		return false
	runtime.decision_log.log(runtime.time, indices[0], instance.mechanic.id, "ai_call_soak_routing", "resolved")
	return true
