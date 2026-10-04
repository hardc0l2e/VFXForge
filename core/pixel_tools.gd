class_name PixelTools
extends RefCounted

static func line(canvas: PixelCanvas, from: Vector2i, to: Vector2i, color: Color) -> void:
	var delta := (to - from).abs()
	var step := Vector2i(1 if from.x < to.x else -1, 1 if from.y < to.y else -1)
	var error := delta.x - delta.y
	var position := from
	while true:
		canvas.set_pixel(position, color)
		if position == to:
			break
		var twice := error * 2
		if twice > -delta.y:
			error -= delta.y
			position.x += step.x
		if twice < delta.x:
			error += delta.x
			position.y += step.y

static func rectangle(canvas: PixelCanvas, rect: Rect2i, color: Color, filled: bool = false) -> void:
	var area := rect.abs()
	if filled:
		for y in range(area.position.y, area.end.y):
			for x in range(area.position.x, area.end.x):
				canvas.set_pixel(Vector2i(x, y), color)
		return
	line(canvas, area.position, Vector2i(area.end.x - 1, area.position.y), color)
	line(canvas, area.position, Vector2i(area.position.x, area.end.y - 1), color)
	line(canvas, Vector2i(area.end.x - 1, area.position.y), area.end - Vector2i.ONE, color)
	line(canvas, Vector2i(area.position.x, area.end.y - 1), area.end - Vector2i.ONE, color)

static func flood_fill(canvas: PixelCanvas, start: Vector2i, color: Color) -> void:
	var target := canvas.get_pixel(start)
	if target == color or not Rect2i(Vector2i.ZERO, canvas.size).has_point(start):
		return
	var pending: Array[Vector2i] = [start]
	while not pending.is_empty():
		var position: Vector2i = pending.pop_back()
		if not Rect2i(Vector2i.ZERO, canvas.size).has_point(position) or canvas.get_pixel(position) != target:
			continue
		canvas.set_pixel(position, color)
		pending.append(position + Vector2i.RIGHT)
		pending.append(position + Vector2i.LEFT)
		pending.append(position + Vector2i.UP)
		pending.append(position + Vector2i.DOWN)

static func mirror_horizontal(canvas: PixelCanvas) -> PixelCanvas:
	var result := PixelCanvas.new(canvas.size)
	for y in canvas.size.y:
		for x in canvas.size.x:
			result.set_pixel(Vector2i(canvas.size.x - 1 - x, y), canvas.get_pixel(Vector2i(x, y)))
	return result
