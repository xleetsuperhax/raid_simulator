class_name DpsExoticController
extends CharacterBody3D

## DPS-Exotic v1 (design doc §3.4): a passive low damage floor from basic
## actions, plus a rhythm minigame on its own cooldown that gates a much
## bigger damage window. The point isn't the movement (duplicated from
## TankController — see its header comment) — it's that the minigame runs
## on top of the same WASD movement and the same boss-mechanic timers as
## everything else, so committing to it while, say, Volatile Rupture is
## about to target you is a genuine split-attention trade-off.
##
## Controls: WASD move, R start the minigame once its cooldown is up,
## SPACE to hit each note as it reaches the hit zone (see RhythmLane for the
## visual — notes fall from the top of the lane and arrive at the zone
## exactly BEAT_INTERVAL apart, NOTE_TRAVEL_TIME after spawning).
##
## Known gap (flagged, not fixed here): FleeDetonationResolver still
## auto-resolves Volatile Rupture even when it targets this seat — the
## "boss mechanics keep demanding attention" tension is real (the timers
## don't stop), but there's no actual fail state yet if you ignore a flee
## while mid-minigame. Wiring a real position-based check for that mechanic
## is a natural next step, same shape as StackingSwapResolver's is_player
## branch, but is out of scope for this change.

const MOVE_SPEED := 5.0
const GRAVITY := 20.0

const BEAT_COUNT := 5
const BEAT_INTERVAL := 0.6
const NOTE_TRAVEL_TIME := 1.2  # seconds a note takes to fall from spawn to the hit zone; read by RhythmLane
const HIT_WINDOW := 0.18
const SUCCESS_HITS_REQUIRED := 4
const BIG_DAMAGE := 100.0
const MINIGAME_COOLDOWN := 18.0
const PASSIVE_TICK_INTERVAL := 2.0
const PASSIVE_DAMAGE := 10.0

enum MinigameState { IDLE, ACTIVE }

var runtime = null  # EncounterRuntime; untyped to avoid a script cross-reference
var seat_index: int = -1

var total_damage: float = 0.0
var minigame_state: int = MinigameState.IDLE
var cooldown_remaining: float = 0.0
var beat_index: int = 0
var beats_hit: int = 0
var last_result: String = ""

## Time since the minigame started (0 at the R press). RhythmLane reads this
## plus beat_index/BEAT_INTERVAL/NOTE_TRAVEL_TIME to place falling notes.
var sequence_timer: float = 0.0

## Per-beat outcome: "" while pending, then "hit" or "miss" once that beat's
## window closes. Read by RhythmLane to color notes; sized to BEAT_COUNT by
## _start_minigame().
var beat_results: Array = []

var _passive_timer: float = 0.0
var _beat_consumed: bool = false
var _start_was_down := false
var _hit_was_down := false

@onready var camera: Camera3D = $CameraPivot/Camera3D

func bind(rt, p_seat_index: int) -> void:
	runtime = rt
	seat_index = p_seat_index
	camera.current = true

func _physics_process(delta: float) -> void:
	var input_dir := Vector3.ZERO
	if Input.is_physical_key_pressed(KEY_W):
		input_dir.z -= 1.0
	if Input.is_physical_key_pressed(KEY_S):
		input_dir.z += 1.0
	if Input.is_physical_key_pressed(KEY_A):
		input_dir.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D):
		input_dir.x += 1.0
	if input_dir.length() > 0.001:
		input_dir = input_dir.normalized()

	velocity.x = input_dir.x * MOVE_SPEED
	velocity.z = input_dir.z * MOVE_SPEED
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= GRAVITY * delta
	move_and_slide()

	_passive_timer += delta
	if _passive_timer >= PASSIVE_TICK_INTERVAL:
		_passive_timer -= PASSIVE_TICK_INTERVAL
		total_damage += PASSIVE_DAMAGE

	_update_minigame(delta, Input.is_physical_key_pressed(KEY_R), Input.is_physical_key_pressed(KEY_SPACE))

## Input state passed in rather than read directly, so this can be driven
## from a headless test without depending on the Input singleton's event
## flush timing (which a bare SceneTree script doesn't reliably trigger).
func _update_minigame(delta: float, start_down: bool, hit_down: bool) -> void:
	var hit_just_pressed := hit_down and not _hit_was_down

	if minigame_state == MinigameState.IDLE:
		cooldown_remaining = max(0.0, cooldown_remaining - delta)
		if start_down and not _start_was_down and cooldown_remaining <= 0.0:
			_start_minigame()
	else:
		sequence_timer += delta
		var target_time: float = NOTE_TRAVEL_TIME + beat_index * BEAT_INTERVAL

		if hit_just_pressed and not _beat_consumed:
			if absf(sequence_timer - target_time) <= HIT_WINDOW:
				beats_hit += 1
				_beat_consumed = true
				beat_results[beat_index] = "hit"

		if sequence_timer >= target_time + HIT_WINDOW:
			if beat_results[beat_index] == "":
				beat_results[beat_index] = "miss"
			beat_index += 1
			_beat_consumed = false
			if beat_index >= BEAT_COUNT:
				_finish_minigame()

	_start_was_down = start_down
	_hit_was_down = hit_down

func _start_minigame() -> void:
	minigame_state = MinigameState.ACTIVE
	beat_index = 0
	beats_hit = 0
	sequence_timer = 0.0
	_beat_consumed = false
	last_result = ""
	beat_results = []
	beat_results.resize(BEAT_COUNT)
	beat_results.fill("")

func _finish_minigame() -> void:
	var success := beats_hit >= SUCCESS_HITS_REQUIRED
	if success:
		total_damage += BIG_DAMAGE
		last_result = "HIT! +%d dmg (%d/%d beats)" % [int(BIG_DAMAGE), beats_hit, BEAT_COUNT]
	else:
		last_result = "MISS (%d/%d beats)" % [beats_hit, BEAT_COUNT]
	if runtime != null:
		runtime.decision_log.log(runtime.time, seat_index, "dps_exotic_minigame",
			"player_rhythm_result_%d_of_%d" % [beats_hit, BEAT_COUNT],
			"resolved" if success else "missed")
	minigame_state = MinigameState.IDLE
	cooldown_remaining = MINIGAME_COOLDOWN
