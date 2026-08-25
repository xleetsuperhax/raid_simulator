extends Node3D

## Minimal placeholder scene: runs boss-01's encounter runtime in real time
## purely so the agent overlay (F1) has something live to display. No
## gameplay/camera/kits here yet — that's future scope.

var runtime: EncounterRuntime

func _ready() -> void:
	var encounter: EncounterDefinition = load("res://resources/encounters/boss_01/boss_01.tres")
	runtime = EncounterRuntime.new()
	runtime.setup(encounter, "normal", 0)

	var overlay: Control = preload("res://scenes/ui/agent_overlay.tscn").instantiate()
	add_child(overlay)
	overlay.bind(runtime)
	overlay.visible = true

func _process(delta: float) -> void:
	if runtime != null and not runtime.is_finished():
		runtime.advance(delta)
