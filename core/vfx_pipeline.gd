class_name VFXPipeline
extends RefCounted

const GraphEvaluator = preload("res://core/graph_evaluator.gd")
const ImpactGenerator = preload("res://core/impact_generator.gd")
const PresetPreviewGenerator = preload("res://core/preset_preview_generator.gd")
const FrameBaker = preload("res://core/frame_baker.gd")
const FrameCompositor = preload("res://core/frame_compositor.gd")
const RendererContract = preload("res://core/renderer_contract.gd")

const IMPACT_PRESETS := ["Impact", "Glow Impact"]
const GLOW_RADIUS := 2
const GLOW_STRENGTH := 0.22

static func render(request: Dictionary) -> Dictionary:
	var canvas_size: Vector2i = request.get("canvas_size", Vector2i(32, 32))
	var typed_nodes := _as_typed_nodes(request.get("nodes", []))
	var connections: Array = request.get("connections", [])
	var fallback: Dictionary = request.get("fallback", {}).duplicate()
	fallback["renderer"] = String(request.get("renderer_mode", RendererContract.PIXEL_CPU))

	var parameters := GraphEvaluator.evaluate(typed_nodes, connections, fallback)
	var renderer := String(parameters.get("renderer", RendererContract.PIXEL_CPU))
	var preset_name := String(request.get("preset_name", "Impact"))
	var palette: Array[Color] = request.get("palette", [])
	var seed_value := int(parameters.get("seed", 0))
	var radius := int(parameters.get("radius", 10))
	var intensity := float(parameters.get("intensity", 1.0))
	var frame_count := maxi(1, int(request.get("frame_count", 12)))

	var frames := _generate(canvas_size, preset_name, seed_value, radius, intensity, frame_count, palette, request)
	frames = _apply_layers(frames, parameters, request)

	var capability := RendererContract.describe(renderer)
	var glow := preset_name == "Glow Impact" or renderer == RendererContract.HYBRID
	if glow:
		for index in frames.size():
			frames[index] = FrameCompositor.additive_glow(frames[index], GLOW_RADIUS, GLOW_STRENGTH)

	var warnings: Array[String] = []
	if not bool(capability.get("bake", false)):
		warnings.append("%s output cannot be baked to deterministic pixel frames" % renderer)

	return {
		"frames": frames,
		"parameters": parameters,
		"renderer": renderer,
		"deterministic": bool(capability.get("deterministic", true)),
		"bakeable": bool(capability.get("bake", false)),
		"glow": glow,
		"valid_chain": bool(parameters.get("valid", false)),
		"warnings": warnings,
	}

static func _as_typed_nodes(source: Array) -> Array[Dictionary]:
	var typed: Array[Dictionary] = []
	for node in source:
		typed.append(node)
	return typed

static func _generate(canvas_size: Vector2i, preset_name: String, seed_value: int, radius: int, intensity: float, frame_count: int, palette: Array[Color], request: Dictionary) -> Array[PixelCanvas]:
	if not IMPACT_PRESETS.has(preset_name):
		return PresetPreviewGenerator.generate_frames(canvas_size, seed_value, frame_count, palette, preset_name, radius)
	return ImpactGenerator.generate_frames(canvas_size, seed_value, radius, intensity, frame_count, palette, int(request.get("particle_count", 80)), float(request.get("spread", 1.0)), float(request.get("direction", 0.0)))

static func _apply_layers(frames: Array[PixelCanvas], parameters: Dictionary, request: Dictionary) -> Array[PixelCanvas]:
	var result := frames
	if bool(parameters.get("has_mask", false)) and String(parameters.get("mask_mode", "")) == "Radial":
		var amount := float(parameters.get("mask_amount", 1.0))
		for index in result.size():
			result[index] = FrameBaker.apply_radial_mask(result[index], amount)
	var texture_path := String(parameters.get("texture_path", ""))
	if texture_path.is_empty():
		texture_path = String(request.get("texture_path", ""))
	if not texture_path.is_empty():
		var image := _load_texture(texture_path)
		if image != null:
			for index in result.size():
				result[index] = FrameBaker.apply_texture_alpha(result[index], image)
	return result

static func _load_texture(texture_path: String) -> Image:
	var resolved := ProjectSettings.globalize_path(texture_path) if texture_path.begins_with("res://") else texture_path
	if not FileAccess.file_exists(resolved):
		return null
	return Image.load_from_file(resolved)