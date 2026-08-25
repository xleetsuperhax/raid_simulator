extends Control

## Required tooling (CLAUDE.md): toggle-able panel showing each AI seat's
## current action/target/cooldowns/resources/health/assigned mechanic.
## v1 has no per-kit resources/cooldowns yet, so this shows what the runtime
## actually tracks today: kit, role, active-tank flag, hp_fraction, and the
## most recent mechanic assigned to that seat. Toggle with F1.

@onready var seat_list: VBoxContainer = $Panel/ScrollContainer/SeatList

var runtime = null  # EncounterRuntime; untyped to avoid a script cross-reference
var _f1_was_down := false

func bind(rt) -> void:
	runtime = rt

func _process(_delta: float) -> void:
	var down := Input.is_physical_key_pressed(KEY_F1)
	if down and not _f1_was_down:
		visible = not visible
	_f1_was_down = down

	if visible and runtime != null:
		_refresh()

func _refresh() -> void:
	for child in seat_list.get_children():
		child.queue_free()
	for seat in runtime.seats:
		var label := Label.new()
		var marker := " [ACTIVE TANK]" if seat.active_tank else ""
		var kit_name: String = seat.kit.display_name if seat.kit != null else "?"
		var mechanic_name: String = seat.current_mechanic_id if seat.current_mechanic_id != "" else "-"
		label.text = "#%d %s%s  hp=%d%%  mechanic=%s" % [
			seat.index, kit_name, marker, int(seat.hp_fraction * 100.0), mechanic_name,
		]
		seat_list.add_child(label)
