class_name ImageExporter
extends RefCounted

static func canvas_to_image(source: PixelCanvas, pixel_size: int = 12) -> Image:
	var image := Image.create(source.size.x * pixel_size, source.size.y * pixel_size, false, Image.FORMAT_RGBA8)
	for y in source.size.y:
		for x in source.size.x:
			image.fill_rect(Rect2i(x * pixel_size, y * pixel_size, pixel_size, pixel_size), source.get_pixel(Vector2i(x, y)))
	return image

static func make_sprite_sheet(frames: Array[PixelCanvas], columns: int = 1, pixel_size: int = 12, padding: int = 0) -> Image:
	if frames.is_empty():
		return Image.create(1, 1, false, Image.FORMAT_RGBA8)
	var frame_size := Vector2i(frames[0].size.x * pixel_size, frames[0].size.y * pixel_size)
	var safe_columns := maxi(1, columns)
	var safe_padding := maxi(0, padding)
	var rows := ceili(float(frames.size()) / safe_columns)
	var cell_size := frame_size + Vector2i(safe_padding * 2, safe_padding * 2)
	var sheet := Image.create(cell_size.x * safe_columns, cell_size.y * rows, false, Image.FORMAT_RGBA8)
	for index in frames.size():
		var target := Vector2i((index % safe_columns) * cell_size.x + safe_padding, (index / safe_columns) * cell_size.y + safe_padding)
		sheet.blit_rect(canvas_to_image(frames[index], pixel_size), Rect2i(Vector2i.ZERO, frame_size), target)
	return sheet
