class_name SubViewportBaker
extends RefCounted

signal capture_progress(frame_index: int, frame_count: int)

## Captures a live SubViewport into transparent images. The caller owns the
## viewport and effect; this bridge only advances the scene and reads pixels.
func capture(viewport: SubViewport, frame_count: int, frames_per_second: float = 24.0) -> Array[Image]:
	var captured: Array[Image] = []
	if viewport == null or frame_count <= 0:
		return captured
	var delta := 1.0 / maxf(frames_per_second, 1.0)
	for frame_index in frame_count:
		await _advance_viewport(viewport, delta)
		var image := viewport.get_texture().get_image()
		if image != null:
			image.convert(Image.FORMAT_RGBA8)
			captured.append(image)
		capture_progress.emit(frame_index + 1, frame_count)
	return captured

func _advance_viewport(viewport: SubViewport, delta: float) -> void:
	viewport.process_mode = Node.PROCESS_MODE_ALWAYS
	await Engine.get_main_loop().process_frame
	if viewport.has_method("advance_effect"):
		viewport.call("advance_effect", delta)
	await Engine.get_main_loop().process_frame

static func images_to_pixel_canvases(images: Array[Image], target_size: Vector2i) -> Array[PixelCanvas]:
	var frames: Array[PixelCanvas] = []
	for image in images:
		var canvas := PixelCanvas.new(target_size)
		for y in target_size.y:
			for x in target_size.x:
				var sx := mini(image.get_width() - 1, int(float(x) * image.get_width() / target_size.x))
				var sy := mini(image.get_height() - 1, int(float(y) * image.get_height() / target_size.y))
				canvas.set_pixel(Vector2i(x, y), image.get_pixel(sx, sy))
		frames.append(canvas)
	return frames
