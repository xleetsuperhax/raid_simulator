class_name KitRegistry
extends RefCounted

## Scans res://resources/kits/ for KitDefinition resources and returns them
## keyed by id, so RaidComposition.kit_counts (kit id -> count) can be
## resolved without a hardcoded kit list.
static func load_all(dir_path: String = "res://resources/kits/") -> Dictionary:
	var result: Dictionary = {}
	var dir := DirAccess.open(dir_path)
	if dir == null:
		push_error("KitRegistry: cannot open %s" % dir_path)
		return result
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var kit: KitDefinition = load(dir_path + file_name)
			if kit != null and kit.id != "":
				result[kit.id] = kit
		file_name = dir.get_next()
	dir.list_dir_end()
	return result
