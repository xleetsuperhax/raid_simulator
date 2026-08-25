extends Control

## Minimal readout for the DPS-Exotic minigame: damage tally, cooldown/ready
## prompt, live beat progress while active, and the last result. Polled each
## frame, same pattern as the agent overlay — no signals needed for this size
## of UI.

@onready var label: Label = $Label

var controller = null  # DpsExoticController; untyped to avoid a script cross-reference

func bind(c) -> void:
	controller = c

func _process(_delta: float) -> void:
	if controller == null:
		return

	var lines: Array[String] = []
	lines.append("Damage: %d" % int(controller.total_damage))

	if controller.minigame_state == DpsExoticController.MinigameState.ACTIVE:
		lines.append("BEAT %d/%d — hit SPACE!" % [controller.beat_index + 1, DpsExoticController.BEAT_COUNT])
	elif controller.cooldown_remaining > 0.0:
		lines.append("Big window in %.1fs" % controller.cooldown_remaining)
	else:
		lines.append("Big window READY — press R")

	if controller.last_result != "":
		lines.append(controller.last_result)

	label.text = "\n".join(lines)
