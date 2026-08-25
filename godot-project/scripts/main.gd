extends Node3D

## Minimal placeholder scene: waits for the player to pick a seat (1: Tank,
## 2: DPS-Exotic), then runs boss-01's encounter runtime in real time with
## that seat player-controlled. No proper menu yet — this is a one-line
## selection step, upgrade it once a third kit makes it worth building one.

const TankCharacterScene := preload("res://scenes/player/tank_character.tscn")
const DpsExoticCharacterScene := preload("res://scenes/player/dps_exotic_character.tscn")
const DpsExoticHudScene := preload("res://scenes/ui/dps_exotic_hud.tscn")
const RhythmLaneScene := preload("res://scenes/ui/rhythm_lane.tscn")

var runtime: EncounterRuntime

@onready var _selection_prompt: Label = $UI/SelectionPrompt
@onready var _controls_hint: Label = $UI/ControlsHint
@onready var _overlay = $UI/AgentOverlay
@onready var _arena: ArenaView = $ArenaView

func _ready() -> void:
	_overlay.visible = false

func _process(delta: float) -> void:
	if runtime == null:
		_handle_selection()
		return
	if not runtime.is_finished():
		runtime.advance(delta)

func _handle_selection() -> void:
	if Input.is_physical_key_pressed(KEY_1):
		_start_encounter("tank")
	elif Input.is_physical_key_pressed(KEY_2):
		_start_encounter("dps_exotic")

func _start_encounter(player_kit_id: String) -> void:
	_selection_prompt.visible = false

	var encounter: EncounterDefinition = load("res://resources/encounters/boss_01/boss_01.tres")
	runtime = EncounterRuntime.new()
	runtime.setup(encounter, "normal", 0, player_kit_id)

	_overlay.bind(runtime)
	_overlay.visible = true

	_arena.build(runtime, runtime.player_seat_index)

	if runtime.player_seat_index < 0:
		return

	var start_position: Vector3 = ArenaView.ring_position(runtime.player_seat_index, runtime.seats.size())

	if player_kit_id == "tank":
		_controls_hint.text = "WASD move   T taunt   F1 toggle overlay"
		var player: TankController = TankCharacterScene.instantiate()
		add_child(player)
		player.position = start_position
		player.bind(runtime, runtime.player_seat_index)
	elif player_kit_id == "dps_exotic":
		_controls_hint.text = "WASD move   R start minigame   SPACE on the beat   F1 toggle overlay"
		var player: DpsExoticController = DpsExoticCharacterScene.instantiate()
		add_child(player)
		player.position = start_position
		player.bind(runtime, runtime.player_seat_index)
		var hud = DpsExoticHudScene.instantiate()
		add_child(hud)
		hud.bind(player)
		var lane = RhythmLaneScene.instantiate()
		add_child(lane)
		lane.bind(player)
