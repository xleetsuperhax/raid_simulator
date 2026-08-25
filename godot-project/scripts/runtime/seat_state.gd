class_name SeatState
extends RefCounted

var index: int = -1
var kit: KitDefinition
var role_category: int = GameEnums.RoleCategory.DPS
var is_player: bool = false
var hp_fraction: float = 1.0
var active_tank: bool = false
var stacks: Dictionary = {}
var current_mechanic_id: String = ""
