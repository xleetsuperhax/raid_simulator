extends SceneTree

## Required tooling (CLAUDE.md): headless dry-run mode. Simulates a full
## encounter with every seat AI-controlled and reports completion/duration/
## mechanic failures. Run after any change touching encounter or agent logic:
##
##   godot --headless --path godot-project -s res://scripts/dry_run/dry_run_cli.gd
##
## Exit code 0 on a clean run (no mechanic failures), 1 otherwise.

func _initialize() -> void:
	var encounter: EncounterDefinition = load("res://resources/encounters/boss_01/boss_01.tres")
	var runtime := EncounterRuntime.new()
	runtime.setup(encounter, "normal", 1)

	var dt := 0.25
	while not runtime.is_finished():
		runtime.advance(dt)

	print("")
	print("=== Headless Dry Run: %s ===" % encounter.display_name)
	print("Roster size: %d" % encounter.composition.roster_size)
	print("Duration: %.1fs / %.1fs enrage" % [runtime.time, encounter.enrage_seconds])
	print("Decisions logged: %d" % runtime.decision_log.entries.size())
	print("Mechanic failures: %d" % runtime.failures.size())
	for f in runtime.failures:
		print(" - FAILURE at t=%.1fs: %s (%s)" % [f["time"], f["mechanic_id"], f["consequence"]])

	var ok: bool = runtime.failures.is_empty()
	print("RESULT: %s" % ("PASS" if ok else "FAIL"))
	quit(0 if ok else 1)
