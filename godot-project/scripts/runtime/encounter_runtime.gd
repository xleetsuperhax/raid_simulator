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
var player_seat_index: int = -1  # -1 means no seat is player-controlled (e.g. the headless dry-run)

## player_kit_id, if non-empty, marks the seat holding that kit as player-
## controlled (SeatState.is_player = true) instead of AI. Resolvers branch on
## this — see StackingSwapResolver — everything else about that seat is
## identical to an AI seat. Omitted entirely by the headless dry-run, so its
## all-AI regression behavior is unchanged.
func setup(p_encounter: EncounterDefinition, tier_id: String = "", seed: int = 0, player_kit_id: String = "") -> void:
	encounter = p_encounter
	rng = RandomNumberGenerator.new()
	rng.seed = seed
	decision_log = DecisionLog.new()
	failures = []
	last_instance = {}
	timers = {}
	time = 0.0
	player_seat_index = -1

	mechanics = _apply_tier(encounter, tier_id)
	resolvers = _build_resolvers()
	_build_seats()

	if player_kit_id != "":
		for seat in seats:
			if seat.kit != null and seat.kit.id == player_kit_id:
				seat.is_player = true
				player_seat_index = seat.index
				break

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
		_apply_failure_effect(instance)
	return ok

## Called by the player's controller when they press Taunt. Only meaningful
## for a player-controlled off-tank — StackingSwapResolver stops auto-resolving
## the swap once the eligible off-tank is a player seat, so this is the only
## way that swap happens; not taking it before the stack threshold is a
## genuine failure (tank_lethal_spike), same as an AI off-tank failing to
## exist would be.
func player_taunt(seat_index: int) -> bool:
	if seat_index < 0 or seat_index >= seats.size():
		return false
	var mechanic: MechanicDefinition = _find_mechanic_by_resolver_id("stacking_swap")
	if mechanic == null:
		return false
	var seat: SeatState = seats[seat_index]
	if seat.role_category != GameEnums.RoleCategory.TANK or seat.active_tank:
		return false
	var current_active: SeatState = get_active_tank()
	if current_active == null:
		return false

	var stacks_at_swap: int = int(current_active.stacks.get(mechanic.id, 0))
	current_active.active_tank = false
	current_active.stacks[mechanic.id] = 0
	seat.active_tank = true
	seat.current_mechanic_id = mechanic.id

	var instance := MechanicInstance.new(mechanic, time)
	instance.data["outgoing_tank_seat_index"] = current_active.index
	instance.data["stacks_at_swap"] = stacks_at_swap
	last_instance[mechanic.id] = instance

	decision_log.log(time, seat.index, mechanic.id, "player_taunt_swap", "resolved")
	_fire_event(mechanic.id, "resolved")
	return true

func _find_mechanic_by_resolver_id(resolver_id: String) -> MechanicDefinition:
	for m in mechanics:
		if m.resolver_id == resolver_id:
			return m
	return null

## No real damage model yet (no kits implemented) — a failed mechanic just
## zeroes the affected seat's hp_fraction as a visible stand-in for "this went
## badly," so failing to act is never silently invisible. See boss-01.md §6.
func _apply_failure_effect(instance: MechanicInstance) -> void:
	var seat_idx = instance.data.get("hit_seat_index", instance.data.get("target_seat_index", -1))
	if seat_idx == null or int(seat_idx) < 0:
		return
	seats[int(seat_idx)].hp_fraction = 0.0

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
