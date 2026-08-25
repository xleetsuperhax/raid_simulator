extends Node3D

## Minimal placeholder scene: runs boss-01's encounter runtime in real time,
## purely so the arena view and agent overlay (F1) have something live to
## display. No gameplay/kits/player input here yet — that's future scope.

var runtime: EncounterRuntime

func _ready() -> void:
	var encounter: EncounterDefinition = load("res://resources/encounters/boss_01/boss_01.tres")
	runtime = EncounterRuntime.new()
	runtime.setup(encounter, "normal", 0)

	var overlay = $UI/AgentOverlay
	overlay.bind(runtime)
	overlay.visible = true

	var arena: ArenaView = $ArenaView
	arena.build(runtime)

func _process(delta: float) -> void:
	if runtime != null and not runtime.is_finished():
		runtime.advance(delta)
