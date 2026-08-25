class_name MechanicInstance
extends RefCounted

## One runtime occurrence of a MechanicDefinition firing. `data` is a loose bag
## resolvers use to pass their own state between on_trigger/resolve and to
## downstream ON_MECHANIC_EVENT listeners (see EncounterRuntime.last_instance).
var mechanic: MechanicDefinition
var trigger_time: float
var data: Dictionary = {}

func _init(p_mechanic: MechanicDefinition = null, p_time: float = 0.0) -> void:
	mechanic = p_mechanic
	trigger_time = p_time
