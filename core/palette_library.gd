class_name PaletteLibrary
extends RefCounted

var sets: Array[PaletteSet] = []

func add_set(palette: PaletteSet) -> void:
	sets.append(palette)

func find(palette_name: String) -> PaletteSet:
	for palette in sets:
		if palette.name == palette_name:
			return palette
	return null

func serialize() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for palette in sets:
		result.append(palette.serialize())
	return result

static func scan_png_names(directory: String = "res://palette") -> Array[String]:
	var names: Array[String] = []
	var palette_dir := DirAccess.open(directory)
	if palette_dir == null:
		return names
	palette_dir.list_dir_begin()
	var file_name := palette_dir.get_next()
	while not file_name.is_empty():
		if not palette_dir.current_is_dir() and file_name.to_lower().ends_with(".png"):
			names.append(file_name.get_basename())
		file_name = palette_dir.get_next()
	palette_dir.list_dir_end()
	names.sort()
	return names
