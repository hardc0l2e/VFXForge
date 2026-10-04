class_name ProjectManager
extends RefCounted

const MAX_RECENT := 12

static func add_recent(paths: Array, path: String) -> Array[String]:
	var result: Array[String] = []
	var normalized := path.replace("\\", "/")
	if not normalized.is_empty():
		result.append(normalized)
	for existing in paths:
		var value := String(existing).replace("\\", "/")
		if not value.is_empty() and value != normalized and not result.has(value):
			result.append(value)
		if result.size() >= MAX_RECENT:
			break
	return result

static func read(path: String) -> Array[String]:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return []
	var parsed = JSON.parse_string(file.get_as_text())
	var result: Array[String] = []
	if parsed is Array:
		for value in parsed:
			if not String(value).is_empty():
				result.append(String(value))
	return result

static func write(path: String, paths: Array) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(paths.slice(0, MAX_RECENT)))
	return true
