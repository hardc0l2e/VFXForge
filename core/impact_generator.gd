class_name ImpactGenerator
extends RefCounted

static func generate(canvas_size: Vector2i, seed_value: int, radius: int, intensity: float, palette: Array[Color], particle_count: int = 80, spread: float = 1.0, direction: float = 0.0) -> PixelCanvas:
	var canvas := PixelCanvas.new(canvas_size)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var center := Vector2(canvas_size) / 2.0
	var max_radius: int = maxi(1, radius)

	for y in canvas_size.y:
		for x in canvas_size.x:
			var offset := Vector2(x, y) - center
			var distance: float = offset.length()
			var normalized: float = distance / float(max_radius)
			var threshold: float = rng.randf_range(0.0, 1.0)
			var angle: float = atan2(offset.y, offset.x)
			var direction_factor: float = 0.5 + 0.5 * cos(angle - direction)
			var density: float = clampf(float(particle_count) / 80.0, 0.1, 2.0)
			var strength: float = clampf((1.0 - normalized / max(spread, 0.1)) * intensity * density * (0.65 + direction_factor * 0.35), 0.0, 1.0)
			if threshold < strength:
				var palette_index := clampi(int((1.0 - normalized) * palette.size()), 0, palette.size() - 1)
				canvas.set_pixel(Vector2i(x, y), palette[palette_index])

	return canvas

static func generate_frames(canvas_size: Vector2i, seed_value: int, radius: int, intensity: float, frame_count: int, palette: Array[Color], particle_count: int = 80, spread: float = 1.0, direction: float = 0.0) -> Array[PixelCanvas]:
	var frames: Array[PixelCanvas] = []
	for frame in frame_count:
		var frame_radius: int = maxi(1, int(radius * (1.0 + float(frame) / max(1, frame_count - 1))))
		var frame_intensity: float = intensity * (1.0 - float(frame) / max(1, frame_count) * 0.65)
		frames.append(generate(canvas_size, seed_value + frame * 7919, frame_radius, frame_intensity, palette, particle_count, spread, direction))
	return frames
