class_name GroupedSoakResolver
extends MechanicResolver

## resolver_id "grouped_soak" — e.g. overflowing_wrath_soak. Whole raid splits
## into ceil(raid_size / group_size) groups.

func on_trigger(mechanic: MechanicDefinition, runtime) -> MechanicInstance:
	var instance := MechanicInstance.new(mechanic, runtime.time)
	var pool: Array = runtime.select_responders(mechanic.responder)
	var group_size: int = int(mechanic.params.get("group_size", 5))
	instance.data["raid_size"] = pool.size()
	instance.data["group_size"] = group_size
	instance.data["group_count"] = int(ceil(float(pool.size()) / float(max(group_size, 1))))
	return instance

func resolve(instance: MechanicInstance, runtime) -> bool:
	if int(instance.data.get("raid_size", 0)) <= 0:
		return false
	runtime.decision_log.log(runtime.time, -1, instance.mechanic.id,
		"ai_raid_forms_%d_groups_of_%d" % [instance.data["group_count"], instance.data["group_size"]],
		"resolved")
	return true
