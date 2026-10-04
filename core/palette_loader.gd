class_name PaletteLoader
extends RefCounted

static func load_png(path: String) -> Array[Color]:
	var image := Image.load_from_file(path)
	if image == null or image.is_empty():
		return []
	var colors: Array[Color] = []
	for y in image.get_height():
		for x in image.get_width():
			var color := image.get_pixel(x, y)
			if color.a <= 0.0:
				continue
			var duplicate := false
			for existing in colors:
				if existing.is_equal_approx(color):
					duplicate = true
					break
			if not duplicate:
				colors.append(color)
	return colors

static func save_png(path: String, colors: Array[Color]) -> bool:
	if colors.is_empty():
		return false
	var image := Image.create(colors.size(), 1, false, Image.FORMAT_RGBA8)
	for index in colors.size():
		image.set_pixel(index, 0, colors[index])
	return image.save_png(path) == OK
