class_name EncounterRuntime
extends RefCounted

## Drives one encounter simulation: schedules mechanic triggers (timer/on-hit/
## chained), runs them through the matching resolver, and records the result.
## Used both by the real-time demo (scripts/main.gd, ticked from _process) and
## the headless dry-run (scripts/dry_run/dry_run_cli.gd, ticked in a tight loop).

var encounter: EncounterDefinition
var mechanics: Array = []  # tier-applied MechanicDefinition copies (never the loaded originals — see _apply_tier)
var seats: Array = []  # SeatState
var resolvers: Dictionary = {}  # resolver_id -> MechanicResolver
var timers: Dictionary = {}  # mechanic_id -> next fire time, for TIMER/ON_HIT mechanics
var last_instance: Dictionary = {}  # mechanic_id -> most recent MechanicInstance
var failures: Array = []  # [{time, mechanic_id, consequence}]
var decision_log: DecisionLog
var rng: RandomNumberGenerator
var time: float = 0.0

func setup(p_encounter: EncounterDefinition, tier_id: String = "", seed: int = 0) -> void:
	encounter = p_encounter
	rng = RandomNumberGenerator.new()
	rng.seed = seed
	decision_log = DecisionLog.new()
	failures = []
	last_instance = {}
	timers = {}
	time = 0.0

	mechanics = _apply_tier(encounter, tier_id)
	resolvers = _build_resolvers()
	_build_seats()

	for m in mechanics:
		if m.trigger.type != GameEnums.TriggerType.ON_MECHANIC_EVENT:
			timers[m.id] = m.trigger.offset_seconds

func is_finished() -> bool:
	return time >= encounter.enrage_seconds

func advance(dt: float) -> void:
	time += dt
	for m in mechanics:
		if m.trigger.type == GameEnums.TriggerType.ON_MECHANIC_EVENT:
			continue
		if not timers.has(m.id):
			continue
		var guard := 0
		while time >= timers[m.id] and guard < 1000:
			fire_mechanic(m)
			var interval: float = m.trigger.interval_seconds
			if interval <= 0.0:
				timers.erase(m.id)
				break
			timers[m.id] += interval
			guard += 1

func fire_mechanic(mechanic: MechanicDefinition) -> bool:
	var resolver: MechanicResolver = resolvers.get(mechanic.resolver_id)
	if resolver == null:
		push_error("No resolver registered for resolver_id '%s'" % mechanic.resolver_id)
		failures.append({"time": time, "mechanic_id": mechanic.id, "consequence": mechanic.failure_consequence})
		return false

	var instance: MechanicInstance = resolver.on_trigger(mechanic, self)
	last_instance[mechanic.id] = instance
	_fire_event(mechanic.id, "triggered")

	var ok: bool = resolver.resolve(instance, self)
	if ok:
		if instance.data.get("chain_event", true):
			_fire_event(mechanic.id, "resolved")
	else:
		failures.append({"time": time, "mechanic_id": mechanic.id, "consequence": mechanic.failure_consequence})
		decision_log.log(time, -1, mechanic.id, "resolution_failed", "failed:%s" % mechanic.failure_consequence)
	return ok

func select_responders(responder: ResponderDefinition) -> Array:
	var pool: Array = []
	if responder.mode == GameEnums.ResponderMode.WHOLE_RAID:
		pool = seats.duplicate()
	else:
		for seat in seats:
			if responder.role_categories.has(seat.role_category):
				pool.append(seat)

	if responder.exclusion == GameEnums.ExclusionRule.NOT_CURRENT_TANK:
		var filtered: Array = []
		for seat in pool:
			if not seat.active_tank:
				filtered.append(seat)
		pool = filtered

	if responder.selection == GameEnums.SelectionMode.RANDOM_ONE:
		if pool.is_empty():
			return []
		return [pool[rng.randi_range(0, pool.size() - 1)]]

	return pool

func get_active_tank() -> SeatState:
	for seat in seats:
		if seat.role_category == GameEnums.RoleCategory.TANK and seat.active_tank:
			return seat
	return null

func get_inactive_tank() -> SeatState:
	for seat in seats:
		if seat.role_category == GameEnums.RoleCategory.TANK and not seat.active_tank:
			return seat
	return null

func _fire_event(source_id: String, event_name: String) -> void:
	for m in mechanics:
		if m.trigger.type == GameEnums.TriggerType.ON_MECHANIC_EVENT \
				and m.trigger.source_mechanic_id == source_id \
				and m.trigger.source_event == event_name:
			fire_mechanic(m)

func _apply_tier(p_encounter: EncounterDefinition, tier_id: String) -> Array:
	var tier: DifficultyTier = null
	for t in p_encounter.tiers:
		if t.id == tier_id:
			tier = t
			break

	var result: Array = []
	for m in p_encounter.mechanics:
		# duplicate(true): loaded Resources are cache-shared, so mutating
		# params in place would corrupt the source .tres for every caller.
		var copy: MechanicDefinition = m.duplicate(true)
		if tier != null and tier.param_overrides.has(m.id):
			var overrides: Dictionary = tier.param_overrides[m.id]
			for k in overrides:
				copy.params[k] = overrides[k]
		result.append(copy)
	return result

func _build_resolvers() -> Dictionary:
	return {
		"stacking_swap": StackingSwapResolver.new(),
		"grouped_soak": GroupedSoakResolver.new(),
		"soak_router": SoakRouterResolver.new(),
		"flee_detonation": FleeDetonationResolver.new(),
		"focus_heal_dot": FocusHealDotResolver.new(),
	}

func _build_seats() -> void:
	seats = []
	var kit_registry: Dictionary = KitRegistry.load_all()
	var idx := 0
	for kit_id in encounter.composition.kit_counts:
		var count: int = int(encounter.composition.kit_counts[kit_id])
		var kit: KitDefinition = kit_registry.get(kit_id)
		if kit == null:
			push_error("EncounterRuntime: unknown kit id '%s' in raid composition" % kit_id)
			continue
		for i in range(count):
			var seat := SeatState.new()
			seat.index = idx
			seat.kit = kit
			seat.role_category = kit.role_category
			seats.append(seat)
			idx += 1

	var first_tank := true
	for seat in seats:
		if seat.role_category == GameEnums.RoleCategory.TANK:
			seat.active_tank = first_tank
			first_tank = false
