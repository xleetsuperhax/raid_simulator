class_name TankController
extends CharacterBody3D

## Tank v1 controls: WASD moves in world space (no camera-relative rotation —
## the camera stays at a fixed offset behind the character, so world-space
## and "forward" line up), T taunts. Raw key polling rather than an input
## action map, matching the pattern already used for the overlay's F1 toggle.
##
## The WASD/camera-follow block below is duplicated in DpsExoticController
## rather than factored into a shared base — with only two kits it's cheaper
## to read as two small self-contained scripts. If a third kit needs the same
## movement, that's the trigger to extract it (CLAUDE.md: no premature
## abstraction).

const MOVE_SPEED := 5.0
const GRAVITY := 20.0

var runtime = null  # EncounterRuntime; untyped to avoid a script cross-reference
var seat_index: int = -1
var _taunt_was_down := false

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

	var taunt_down := Input.is_physical_key_pressed(KEY_T)
	if taunt_down and not _taunt_was_down and runtime != null:
		runtime.player_taunt(seat_index)
	_taunt_was_down = taunt_down
