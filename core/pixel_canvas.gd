class_name PixelCanvas
extends RefCounted

var size: Vector2i
var pixels: PackedColorArray

func _init(canvas_size: Vector2i = Vector2i(32, 32)) -> void:
	size = canvas_size
	pixels.resize(size.x * size.y)
	pixels.fill(Color.TRANSPARENT)

func set_pixel(position: Vector2i, color: Color) -> void:
	if _is_inside(position):
		pixels[position.y * size.x + position.x] = color

func get_pixel(position: Vector2i) -> Color:
	if not _is_inside(position):
		return Color.TRANSPARENT
	return pixels[position.y * size.x + position.x]

func clear() -> void:
	pixels.fill(Color.TRANSPARENT)

func _is_inside(position: Vector2i) -> bool:
	return Rect2i(Vector2i.ZERO, size).has_point(position)
