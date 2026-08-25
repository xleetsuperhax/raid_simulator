class_name RaidComposition
extends Resource

## Roster size is a config value (design doc §8) — never hardcode 25 elsewhere.
@export var roster_size: int = 25

## kit id (String, matches KitDefinition.id) -> seat count. Must sum to roster_size.
@export var kit_counts: Dictionary = {}
