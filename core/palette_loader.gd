class_name PaletteLoader
extends RefCounted

static func load_png(path: String) -> Array[Color]:
	var image := _read_image(path)
	if image == null or image.is_empty():
		return []
	return colors_from_image(image)

## Collects the distinct opaque colours of an image, in scan order.
static func colors_from_image(image: Image) -> Array[Color]:
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

## Reads palette pixels from an imported resource or a plain image file.
##
## Image.load_from_file() only works while the source PNG exists on disk, and an
## exported build stores PNGs as imported resources inside the pack. So res://
## paths always go through ResourceLoader (correct in both contexts, and free of
## Godot's "will not work on export" warning), while absolute and user:// paths
## are plain files on disk and are read directly.
static func _read_image(path: String) -> Image:
	if path.begins_with("res://"):
		var texture := load(path) as Texture2D
		if texture == null:
			return null
		var image := texture.get_image()
		if image != null and image.is_compressed():
			image.decompress()
		return image
	if FileAccess.file_exists(path):
		return Image.load_from_file(path)
	return null

static func save_png(path: String, colors: Array[Color]) -> bool:
	if colors.is_empty():
		return false
	var image := Image.create(colors.size(), 1, false, Image.FORMAT_RGBA8)
	for index in colors.size():
		image.set_pixel(index, 0, colors[index])
	return image.save_png(path) == OK
