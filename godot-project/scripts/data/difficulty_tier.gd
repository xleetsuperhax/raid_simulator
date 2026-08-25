class_name DifficultyTier
extends Resource

@export var id: String
## mechanic id (String) -> Dictionary(param_name -> value). Sparse: only lists
## what this tier changes from the mechanic's base params.
@export var param_overrides: Dictionary = {}
