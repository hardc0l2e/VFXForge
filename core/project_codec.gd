class_name ProjectCodec
extends RefCounted

static func encode(project: Dictionary) -> String:
	return JSON.stringify(project, "  ")

static func decode(text: String) -> Dictionary:
	var parsed = JSON.parse_string(text)
	return parsed if parsed is Dictionary else {}

static func write(path: String, project: Dictionary) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(encode(project))
	return true

static func read(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	return decode(file.get_as_text())
