class_name StylePackLibrary
extends RefCounted

static func builtins() -> Array[Dictionary]:
	return [
		{"name": "Haribon Ember", "colors": ["fff4c2", "ffcf5c", "f2764b", "a83d56"]},
		{"name": "Haribon Frost", "colors": ["e5fff9", "78ffd9", "43b9d1", "31558c"]},
		{"name": "Haribon Arcane", "colors": ["f5e8ff", "c89bff", "8c5bd6", "42266f"]},
	]

static func find(name: String) -> Array[Color]:
	for pack in builtins():
		if String(pack.name) != name:
			continue
		var colors: Array[Color] = []
		for value in pack.colors:
			colors.append(Color(String(value)))
		return colors
	return []
