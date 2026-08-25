class_name EncounterDefinition
extends Resource

@export var id: String
@export var display_name: String
@export var composition: RaidComposition
@export var enrage_seconds: float = 0.0
@export var mechanics: Array[MechanicDefinition] = []
@export var tiers: Array[DifficultyTier] = []
