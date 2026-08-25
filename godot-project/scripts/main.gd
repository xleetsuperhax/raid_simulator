extends Node3D

## Minimal placeholder scene: runs boss-01's encounter runtime in real time,
## with the player occupying the Tank seat. No kit selection UI yet — Tank is
## hardcoded here as the only playable seat so far (DPS-Exotic next).

const PlayerCharacterScene := preload("res://scenes/player/player_character.tscn")

var runtime: EncounterRuntime

func _ready() -> void:
	var encounter: EncounterDefinition = load("res://resources/encounters/boss_01/boss_01.tres")
	runtime = EncounterRuntime.new()
	runtime.setup(encounter, "normal", 0, "tank")

	var overlay = $UI/AgentOverlay
	overlay.bind(runtime)
	overlay.visible = true

	var arena: ArenaView = $ArenaView
	arena.build(runtime, runtime.player_seat_index)

	if runtime.player_seat_index >= 0:
		var player: PlayerController = PlayerCharacterScene.instantiate()
		add_child(player)
		player.position = ArenaView.ring_position(runtime.player_seat_index, runtime.seats.size())
		player.bind(runtime, runtime.player_seat_index)

func _process(delta: float) -> void:
	if runtime != null and not runtime.is_finished():
		runtime.advance(delta)
