class_name DecisionLog
extends RefCounted

## Required tooling (CLAUDE.md): "log which rule fired for each AI action".
## seat_index == -1 means the entry isn't about one specific seat (e.g. a
## whole-raid soak resolution).
var entries: Array = []

func log(time: float, seat_index: int, mechanic_id: String, rule: String, outcome: String) -> void:
	var entry := {
		"time": time,
		"seat_index": seat_index,
		"mechanic_id": mechanic_id,
		"rule": rule,
		"outcome": outcome,
	}
	entries.append(entry)
	print("[t=%.1fs] seat=%d mechanic=%s rule=%s -> %s" % [time, seat_index, mechanic_id, rule, outcome])
