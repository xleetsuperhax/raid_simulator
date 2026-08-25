class_name ArenaView
extends Node3D

## Minimal visual read-out of an EncounterRuntime: one capsule per AI seat,
## arranged in a ring around the boss marker, color-coded by role, with the
## active tank's capsule scaled up and a brief flash on whichever seat a
## decision was just logged for. No positions/movement/animation beyond
## that — v1 shouldn't invest in visual fidelity before the base loop works
## (CLAUDE.md). The player's own seat (if any) is excluded from the ring —
## they're represented by a real, player-moved PlayerCharacter instead (see
## scripts/main.gd), starting at the same ring slot this would have used.

const RING_RADIUS := 8.0
const SEAT_RADIUS := 0.4

const ROLE_COLORS := {
	0: Color(0.25, 0.45, 0.9),   # TANK
	1: Color(0.25, 0.85, 0.35),  # HEALER
	2: Color(0.85, 0.3, 0.3),    # DPS
	3: Color(0.85, 0.75, 0.2),   # SUPPORT_PUZZLE
}

var runtime = null  # EncounterRuntime; untyped to avoid a script cross-reference
var _seat_meshes: Dictionary = {}  # seat index -> MeshInstance3D
var _seat_materials: Dictionary = {}  # seat index -> StandardMaterial3D

## Shared with scripts/main.gd so the player's starting position matches
## exactly where their ring slot would otherwise have been drawn.
static func ring_position(seat_index: int, seat_count: int) -> Vector3:
	var angle := TAU * float(seat_index) / float(max(seat_count, 1))
	return Vector3(cos(angle) * RING_RADIUS, SEAT_RADIUS * 1.5, sin(angle) * RING_RADIUS)

func build(rt, exclude_seat_index: int = -1) -> void:
	runtime = rt
	for child in get_children():
		child.queue_free()
	_seat_meshes.clear()
	_seat_materials.clear()

	var count: int = runtime.seats.size()
	for seat in runtime.seats:
		if seat.index == exclude_seat_index:
			continue

		var capsule := CapsuleMesh.new()
		capsule.radius = SEAT_RADIUS
		capsule.height = SEAT_RADIUS * 3.0

		var material := StandardMaterial3D.new()
		material.albedo_color = ROLE_COLORS.get(seat.role_category, Color.WHITE)

		var mesh_instance := MeshInstance3D.new()
		mesh_instance.mesh = capsule
		mesh_instance.material_override = material
		mesh_instance.position = ring_position(seat.index, count)

		add_child(mesh_instance)
		_seat_meshes[seat.index] = mesh_instance
		_seat_materials[seat.index] = material

	if runtime.decision_log != null:
		runtime.decision_log.logged.connect(_on_decision_logged)

func _process(_delta: float) -> void:
	if runtime == null:
		return
	for seat in runtime.seats:
		var mesh_instance: MeshInstance3D = _seat_meshes.get(seat.index)
		if mesh_instance == null:
			continue
		mesh_instance.scale = Vector3.ONE * (1.4 if seat.active_tank else 1.0)

func _on_decision_logged(_time: float, seat_index: int, _mechanic_id: String, _rule: String, _outcome: String) -> void:
	if seat_index < 0:
		return
	var material: StandardMaterial3D = _seat_materials.get(seat_index)
	if material == null:
		return
	var base_color: Color = ROLE_COLORS.get(runtime.seats[seat_index].role_category, Color.WHITE)
	material.albedo_color = Color.WHITE
	create_tween().tween_property(material, "albedo_color", base_color, 0.4)
