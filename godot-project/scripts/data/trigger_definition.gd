class_name TriggerDefinition
extends Resource

@export var type: GameEnums.TriggerType = GameEnums.TriggerType.TIMER

# TIMER, and also ON_HIT (where it's the attack cadence landing on the
# responder, e.g. the boss's auto-attack interval on the active tank)
@export var interval_seconds: float = 0.0
@export var offset_seconds: float = 0.0

# ON_HIT
@export var hit_target_responder: bool = true

# ON_MECHANIC_EVENT — source_event is "triggered" or "resolved"
@export var source_mechanic_id: String = ""
@export var source_event: String = ""
