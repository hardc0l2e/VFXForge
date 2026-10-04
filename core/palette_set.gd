class_name PaletteSet
extends RefCounted

var name := "Untitled"
var colors: Array[Color] = []

func _init(palette_name: String = "Untitled", initial_colors: Array[Color] = []) -> void:
	name = palette_name
	colors = initial_colors.duplicate()

func add_color(color: Color) -> void:
	if not colors.has(color):
		colors.append(color)

func remove_color(index: int) -> void:
	if index >= 0 and index < colors.size():
		colors.remove_at(index)

func serialize() -> Dictionary:
	return {"name": name, "colors": colors.map(func(color: Color) -> String: return color.to_html(true))}

static func deserialize(data: Dictionary):
	var result = preload("res://core/palette_set.gd").new(String(data.get("name", "Untitled")))
	var values = data.get("colors", [])
	if values is Array:
		for value in values:
			result.add_color(Color(String(value)))
	return result
