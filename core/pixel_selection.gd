class_name PixelSelection
extends RefCounted

var bounds := Rect2i()
var pixels: Array[Color] = []

func is_empty() -> bool:
	return bounds.size == Vector2i.ZERO or pixels.is_empty()

func capture(canvas: PixelCanvas, area: Rect2i) -> void:
	bounds = area.abs()
	pixels.clear()
	if bounds.size.x <= 0 or bounds.size.y <= 0:
		bounds = Rect2i()
		return
	for y in bounds.size.y:
		for x in bounds.size.x:
			var position := bounds.position + Vector2i(x, y)
			pixels.append(canvas.get_pixel(position) if Rect2i(Vector2i.ZERO, canvas.size).has_point(position) else Color.TRANSPARENT)

func clear_from(canvas: PixelCanvas) -> void:
	if is_empty():
		return
	for y in bounds.size.y:
		for x in bounds.size.x:
			var position := bounds.position + Vector2i(x, y)
			if Rect2i(Vector2i.ZERO, canvas.size).has_point(position):
				canvas.set_pixel(position, Color.TRANSPARENT)

func paste(canvas: PixelCanvas, destination: Vector2i) -> void:
	if is_empty():
		return
	var canvas_rect := Rect2i(Vector2i.ZERO, canvas.size)
	for y in bounds.size.y:
		for x in bounds.size.x:
			var position := destination + Vector2i(x, y)
			if canvas_rect.has_point(position):
				canvas.set_pixel(position, pixels[y * bounds.size.x + x])

func move(canvas: PixelCanvas, destination: Vector2i) -> void:
	clear_from(canvas)
	paste(canvas, destination)
	bounds.position = destination
