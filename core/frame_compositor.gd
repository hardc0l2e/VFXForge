class_name FrameCompositor
extends RefCounted

static func additive_glow(source: PixelCanvas, radius: int = 2, strength: float = 0.35) -> PixelCanvas:
	var result := PixelCanvas.new(source.size)
	for y in source.size.y:
		for x in source.size.x:
			var base := source.get_pixel(Vector2i(x, y))
			var glow := Color(0, 0, 0, 0)
			for oy in range(-radius, radius + 1):
				for ox in range(-radius, radius + 1):
					if ox == 0 and oy == 0:
						continue
					var distance := Vector2(ox, oy).length()
					if distance > float(radius):
						continue
					var sample_position := Vector2i(clampi(x + ox, 0, source.size.x - 1), clampi(y + oy, 0, source.size.y - 1))
					var sample := source.get_pixel(sample_position)
					var weight := (1.0 - distance / float(radius + 1)) * strength
					glow += Color(sample.r, sample.g, sample.b, sample.a * weight)
			var alpha := clampf(base.a + glow.a, 0.0, 1.0)
			result.set_pixel(Vector2i(x, y), Color(clampf(base.r + glow.r, 0.0, 1.0), clampf(base.g + glow.g, 0.0, 1.0), clampf(base.b + glow.b, 0.0, 1.0), alpha))
	return result

static func composite_additive(base: PixelCanvas, overlay: PixelCanvas, strength: float = 1.0) -> PixelCanvas:
	var result := PixelCanvas.new(base.size)
	for y in base.size.y:
		for x in base.size.x:
			var a := base.get_pixel(Vector2i(x, y))
			var b := overlay.get_pixel(Vector2i(x, y))
			result.set_pixel(Vector2i(x, y), Color(clampf(a.r + b.r * b.a * strength, 0.0, 1.0), clampf(a.g + b.g * b.a * strength, 0.0, 1.0), clampf(a.b + b.b * b.a * strength, 0.0, 1.0), clampf(maxf(a.a, b.a), 0.0, 1.0)))
	return result
