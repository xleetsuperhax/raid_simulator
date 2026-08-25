class_name ResponderDefinition
extends Resource

@export var mode: GameEnums.ResponderMode = GameEnums.ResponderMode.BY_ROLE
@export var role_categories: Array[GameEnums.RoleCategory] = []
@export var selection: GameEnums.SelectionMode = GameEnums.SelectionMode.ALL_MATCHING
@export var exclusion: GameEnums.ExclusionRule = GameEnums.ExclusionRule.NONE
