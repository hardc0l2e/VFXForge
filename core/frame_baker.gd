class_name FrameBaker
extends RefCounted

static func resize_nearest(source: PixelCanvas, target_size: Vector2i) -> PixelCanvas:
	var target := PixelCanvas.new(Vector2i(maxi(1, target_size.x), maxi(1, target_size.y)))
	for y in target.size.y:
		for x in target.size.x:
			var source_x := mini(source.size.x - 1, int(float(x) * source.size.x / target.size.x))
			var source_y := mini(source.size.y - 1, int(float(y) * source.size.y / target.size.y))
			target.set_pixel(Vector2i(x, y), source.get_pixel(Vector2i(source_x, source_y)))
	return target

static func bake_frames(frames: Array[PixelCanvas], target_size: Vector2i) -> Array[PixelCanvas]:
	var baked: Array[PixelCanvas] = []
	for frame in frames:
		baked.append(resize_nearest(frame, target_size))
	return baked

static func apply_radial_mask(frame: PixelCanvas, amount: float) -> PixelCanvas:
	var result := PixelCanvas.new(frame.size)
	var center := Vector2(frame.size) * 0.5
	var radius := minf(frame.size.x, frame.size.y) * 0.5 * clampf(amount, 0.05, 1.0)
	for y in frame.size.y:
		for x in frame.size.x:
			if Vector2(x, y).distance_to(center) <= radius:
				result.set_pixel(Vector2i(x, y), frame.get_pixel(Vector2i(x, y)))
	return result

static func apply_texture_alpha(frame: PixelCanvas, texture: Image) -> PixelCanvas:
	var result := PixelCanvas.new(frame.size)
	for y in frame.size.y:
		for x in frame.size.x:
			var tx := mini(texture.get_width() - 1, int(float(x) * texture.get_width() / frame.size.x))
			var ty := mini(texture.get_height() - 1, int(float(y) * texture.get_height() / frame.size.y))
			var color := frame.get_pixel(Vector2i(x, y))
			var alpha := texture.get_pixel(tx, ty).a
			result.set_pixel(Vector2i(x, y), color * Color(1.0, 1.0, 1.0, alpha))
	return result
