class_name PreferencesStore
extends RefCounted

const DEFAULTS := {"ui_scale": 1.0, "show_grid": true, "last_renderer": "Pixel CPU", "autosave_minutes": 5}

static func normalize(values: Dictionary) -> Dictionary:
	var result := DEFAULTS.duplicate(true)
	for key in values:
		if result.has(key):
			result[key] = values[key]
	return result

static func write(path: String, values: Dictionary) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(normalize(values)))
	return true

static func read(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return DEFAULTS.duplicate(true)
	var parsed = JSON.parse_string(file.get_as_text())
	return normalize(parsed if parsed is Dictionary else {})
