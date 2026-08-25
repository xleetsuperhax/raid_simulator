extends Control

## Visual for DpsExoticController's minigame: notes fall from the top of the
## lane and the hit zone (a fixed marked band) is where SPACE needs to land.
## Purely a read-out of the controller's timing state — no gameplay logic
## lives here, so the headless-testable timing math in the controller stays
## the source of truth.

const LANE_WIDTH := 80.0
const LANE_HEIGHT := 400.0
const HIT_ZONE_Y := 340.0
const HIT_ZONE_HEIGHT := 24.0
const NOTE_RADIUS := 16.0

const COLOR_LANE := Color(0.1, 0.1, 0.12, 0.6)
const COLOR_HIT_ZONE := Color(0.9, 0.85, 0.2, 0.9)
const COLOR_NOTE_PENDING := Color(0.95, 0.45, 0.1, 1.0)
const COLOR_NOTE_HIT := Color(0.3, 0.9, 0.3, 1.0)
const COLOR_NOTE_MISS := Color(0.85, 0.2, 0.2, 1.0)

var controller = null  # DpsExoticController; untyped to avoid a script cross-reference

func bind(c) -> void:
	controller = c

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(0, 0, LANE_WIDTH, LANE_HEIGHT), COLOR_LANE)
	draw_rect(Rect2(0, HIT_ZONE_Y, LANE_WIDTH, HIT_ZONE_HEIGHT), COLOR_HIT_ZONE, false, 3.0)

	if controller == null or controller.minigame_state != DpsExoticController.MinigameState.ACTIVE:
		return

	var hit_zone_center: float = HIT_ZONE_Y + HIT_ZONE_HEIGHT * 0.5
	var first_visible: int = max(0, controller.beat_index - 1)
	for i in range(first_visible, DpsExoticController.BEAT_COUNT):
		var target_time: float = DpsExoticController.NOTE_TRAVEL_TIME + i * DpsExoticController.BEAT_INTERVAL
		var time_until_hit: float = target_time - controller.sequence_timer
		var fraction: float = 1.0 - (time_until_hit / DpsExoticController.NOTE_TRAVEL_TIME)
		if fraction < -0.2 or fraction > 1.2:
			continue

		var y: float = clampf(fraction, -0.2, 1.2) * hit_zone_center
		var result: String = controller.beat_results[i] if i < controller.beat_results.size() else ""
		var color := COLOR_NOTE_PENDING
		if result == "hit":
			color = COLOR_NOTE_HIT
		elif result == "miss":
			color = COLOR_NOTE_MISS
		draw_circle(Vector2(LANE_WIDTH * 0.5, y), NOTE_RADIUS, color)
