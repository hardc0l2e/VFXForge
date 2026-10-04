class_name PresetPreviewGenerator
extends RefCounted

static func generate_frames(canvas_size: Vector2i, seed_value: int, frame_count: int, palette: Array[Color], preset_name: String, radius_value: float = 14.0) -> Array[PixelCanvas]:
	var frames: Array[PixelCanvas] = []
	for frame in frame_count:
		var canvas := PixelCanvas.new(canvas_size)
		var center := Vector2(canvas_size) * 0.5
		var t := float(frame) / maxf(1.0, float(frame_count - 1))
		match preset_name:
			"Projectile": _draw_projectile(canvas, center, t, palette)
			"Fireball Projectile": _draw_fireball_projectile(canvas, center, t, palette)
			"Lightning Sideways": _draw_lightning(canvas, center, t, palette, false, seed_value + frame)
			"Lightning Downward": _draw_lightning(canvas, center, t, palette, true, seed_value + frame)
			"Spark Burst": _draw_sparks(canvas, center, t, palette, seed_value + frame)
			"AOE Attack": _draw_aoe(canvas, center, t, palette, radius_value)
			_: _draw_named_effect(canvas, center, t, palette, preset_name, seed_value + frame)
		frames.append(canvas)
	return frames

static func _draw_named_effect(canvas: PixelCanvas, center: Vector2, t: float, palette: Array[Color], preset_name: String, seed_value: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var radius := 3.0 + t * minf(canvas.size.x, canvas.size.y) * 0.35
	var name := preset_name.to_lower()
	if name == "slash":
		for index in 24:
			var angle := -1.1 + float(index) / 23.0 * 2.2
			var point := center + Vector2(cos(angle), sin(angle)) * radius
			_paint(canvas, point, palette[index % palette.size()])
	elif name == "lightning":
		var point := Vector2(3.0, center.y)
		for index in canvas.size.x - 6:
			point.x = 3.0 + index
			point.y = center.y + sin(float(index) * 0.8 + t * 5.0) * 4.0 + rng.randf_range(-1.0, 1.0)
			_paint(canvas, point, palette[index % palette.size()])
	else:
		for index in 20:
			var angle := TAU * float(index) / 20.0
			var point := center + Vector2(cos(angle), sin(angle)) * (radius + rng.randf_range(-2.0, 2.0))
			_paint(canvas, point, palette[index % palette.size()])
		for y in canvas.size.y:
			for x in canvas.size.x:
				if Vector2(x, y).distance_to(center) < 2.5:
					_paint(canvas, Vector2(x, y), palette[0])

static func _paint(canvas: PixelCanvas, point: Vector2, color: Color) -> void:
	var pixel := Vector2i(roundi(point.x), roundi(point.y))
	if Rect2i(Vector2i.ZERO, canvas.size).has_point(pixel):
		canvas.set_pixel(pixel, color)

static func _draw_projectile(canvas: PixelCanvas, center: Vector2, t: float, palette: Array[Color]) -> void:
	var head := Vector2(4.0 + t * (canvas.size.x - 8.0), center.y)
	for index in 8:
		_paint(canvas, head - Vector2(index * 1.5, 0), palette[min(index / 3, palette.size() - 1)])
		_paint(canvas, head - Vector2(index * 1.5, 1), palette[min(index / 3, palette.size() - 1)])
	_paint(canvas, head, palette[0])
	_paint(canvas, head + Vector2(0, -1), palette[0])
	_paint(canvas, head + Vector2(0, 1), palette[0])

static func _draw_fireball_projectile(canvas: PixelCanvas, center: Vector2, t: float, palette: Array[Color]) -> void:
	var head := Vector2(5.0 + t * (canvas.size.x - 10.0), center.y)
	for y in canvas.size.y:
		for x in canvas.size.x:
			if Vector2(x, y).distance_to(head) <= 3.0:
				_paint(canvas, Vector2(x, y), palette[mini(2, palette.size() - 1)])
	for index in 10:
		var trail_position := head - Vector2(float(index) * 1.4, 0.0)
		_paint(canvas, trail_position + Vector2(0, sin(float(index) * 1.7 + t * 8.0)), palette[index % palette.size()])
	_paint(canvas, head, palette[0])

static func _draw_lightning(canvas: PixelCanvas, center: Vector2, t: float, palette: Array[Color], downward: bool, seed_value: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var segments := 9
	var start := Vector2(center.x, 2.0) if downward else Vector2(2.0, center.y)
	var finish := Vector2(center.x, float(canvas.size.y - 3)) if downward else Vector2(float(canvas.size.x - 3), center.y)
	var previous := start
	for index in segments + 1:
		var amount := float(index) / float(segments)
		var point := start.lerp(finish, amount)
		var jitter := rng.randf_range(-2.0, 2.0) * sin(t * PI)
		point += Vector2(jitter, 0) if downward else Vector2(0, jitter)
		_draw_line(canvas, previous, point, palette[index % palette.size()])
		previous = point

static func _draw_line(canvas: PixelCanvas, start: Vector2, finish: Vector2, color: Color) -> void:
	var distance := start.distance_to(finish)
	for index in maxi(1, ceili(distance)):
		_paint(canvas, start.lerp(finish, float(index) / distance), color)

static func _draw_sparks(canvas: PixelCanvas, center: Vector2, t: float, palette: Array[Color], seed_value: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for index in 16:
		var angle := TAU * float(index) / 16.0 + rng.randf_range(-0.15, 0.15)
		var radius := 2.0 + t * (canvas.size.x * 0.45) + rng.randf_range(-1.0, 2.0)
		var point := center + Vector2(cos(angle), sin(angle)) * radius
		_paint(canvas, point, palette[index % palette.size()])
		if t > 0.25:
			_paint(canvas, center + (point - center) * 0.75, palette[index % palette.size()])

static func _draw_aoe(canvas: PixelCanvas, center: Vector2, t: float, palette: Array[Color], radius_value: float) -> void:
	# Keep the expanding ring inside the drawable canvas, including its one-pixel edge.
	var safe_radius := maxf(1.0, minf(canvas.size.x, canvas.size.y) * 0.5 - 4.0)
	var radius := minf(maxf(2.0, radius_value) * (0.25 + t * 0.75), safe_radius)
	for y in canvas.size.y:
		for x in canvas.size.x:
			var distance := Vector2(x, y).distance_to(center)
			if absf(distance - radius) <= 1.0:
				_paint(canvas, Vector2(x, y), palette[1 % palette.size()])
			elif distance < 3.0:
				_paint(canvas, Vector2(x, y), palette[0])
