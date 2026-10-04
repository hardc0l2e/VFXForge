class_name PixelHistory
extends RefCounted

var undo_stack: Array[PixelCanvas] = []
var redo_stack: Array[PixelCanvas] = []
var limit := 80

func record(canvas: PixelCanvas) -> void:
	undo_stack.append(_copy(canvas))
	if undo_stack.size() > limit:
		undo_stack.pop_front()
	redo_stack.clear()

func undo(current: PixelCanvas) -> PixelCanvas:
	if undo_stack.is_empty():
		return current
	var restored: PixelCanvas = undo_stack.pop_back() as PixelCanvas
	redo_stack.append(_copy(current))
	return restored

func redo(current: PixelCanvas) -> PixelCanvas:
	if redo_stack.is_empty():
		return current
	var restored: PixelCanvas = redo_stack.pop_back() as PixelCanvas
	undo_stack.append(_copy(current))
	return restored

func clear() -> void:
	undo_stack.clear()
	redo_stack.clear()

func _copy(source: PixelCanvas) -> PixelCanvas:
	var result := PixelCanvas.new(source.size)
	result.pixels = source.pixels.duplicate()
	return result
