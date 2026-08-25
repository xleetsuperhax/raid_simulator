class_name MechanicDefinition
extends Resource

@export var id: String
@export var display_name: String
@export var trigger: TriggerDefinition
@export var responder: ResponderDefinition
@export var resolver_id: String
## Tunable numbers the resolver (matched by resolver_id) reads — see
## docs/architecture/encounter-data-schema.md §5 for the contract per resolver_id.
@export var params: Dictionary = {}
@export var failure_consequence: String
