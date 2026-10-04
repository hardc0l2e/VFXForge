class_name PixelCompositor
extends RefCounted

static func alpha_over(base: Color, overlay: Color) -> Color:
	var alpha := overlay.a + base.a * (1.0 - overlay.a)
	if is_zero_approx(alpha):
		return Color.TRANSPARENT
	var rgb := (overlay * overlay.a + base * base.a * (1.0 - overlay.a)) / alpha
	rgb.a = alpha
	return rgb

static func blend_frames(base: PixelCanvas, overlay: PixelCanvas, opacity: float = 1.0) -> PixelCanvas:
	var result := PixelCanvas.new(base.size)
	var amount := clampf(opacity, 0.0, 1.0)
	for y in base.size.y:
		for x in base.size.x:
			var foreground := overlay.get_pixel(Vector2i(x, y))
			foreground.a *= amount
			result.set_pixel(Vector2i(x, y), alpha_over(base.get_pixel(Vector2i(x, y)), foreground))
	return result
