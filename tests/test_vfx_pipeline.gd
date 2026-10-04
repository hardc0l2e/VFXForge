@tool
extends "res://tests/harness/test_suite.gd"

const VFXPipeline = preload("res://core/vfx_pipeline.gd")
const RendererContract = preload("res://core/renderer_contract.gd")

var FIRE: Array[Color] = [Color("#fff4c2"), Color("#ffb03a"), Color("#ff6a2b"), Color("#c9314f")]

func suite_name() -> String:
	return "vfx_pipeline"

func _chain(output_renderer: String = RendererContract.PIXEL_CPU, seed_value: int = 391822, radius: int = 10, extra_nodes: Array = [], extra_connections: Array = []) -> Dictionary:
	var nodes: Array = [
		{"name": "Seed", "parameters": {"seed": seed_value}},
		{"name": "Burst", "parameters": {"radius": radius, "intensity": 1.0}},
		{"name": "Pixelize", "parameters": {"resolution": 32}},
		{"name": "Palette", "parameters": {"palette": "Fire"}},
		{"name": "Output", "parameters": {"format": "SpriteFrames", "renderer": output_renderer}},
	]
	nodes.append_array(extra_nodes)
	var connections: Array = [
		{"from": 0, "to": 1},
		{"from": 1, "to": 2},
		{"from": 2, "to": 3},
		{"from": 3, "to": 4},
	]
	connections.append_array(extra_connections)
	return {"nodes": nodes, "connections": connections}

func _request(overrides: Dictionary = {}) -> Dictionary:
	var chain := _chain()
	var base: Dictionary = {
		"canvas_size": Vector2i(32, 32),
		"nodes": chain.nodes,
		"connections": chain.connections,
		"renderer_mode": RendererContract.PIXEL_CPU,
		"preset_name": "Impact",
		"palette": FIRE,
		"frame_count": 4,
	}
	base.merge(overrides, true)
	return base

func test_graph_output_renderer_overrides_request_renderer() -> void:
	var cpu_chain := _chain(RendererContract.PIXEL_CPU)
	var hybrid_chain := _chain(RendererContract.HYBRID)
	var cpu := VFXPipeline.render(_request({
		"nodes": cpu_chain.nodes,
		"connections": cpu_chain.connections,
		"renderer_mode": RendererContract.HYBRID,
	}))
	var hybrid := VFXPipeline.render(_request({
		"nodes": hybrid_chain.nodes,
		"connections": hybrid_chain.connections,
		"renderer_mode": RendererContract.PIXEL_CPU,
	}))
	assert_eq(cpu.renderer, RendererContract.PIXEL_CPU)
	assert_eq(hybrid.renderer, RendererContract.HYBRID)
	assert_false(cpu.glow)
	assert_true(hybrid.glow)
	assert_ne(cpu.frames[1].pixels, hybrid.frames[1].pixels)

func test_request_renderer_used_when_output_node_absent() -> void:
	var result := VFXPipeline.render(_request({
		"nodes": [{"name": "Seed", "parameters": {"seed": 7}}],
		"connections": [],
		"renderer_mode": RendererContract.GPU_PARTICLES,
	}))
	assert_eq(result.renderer, RendererContract.GPU_PARTICLES)
	assert_false(result.valid_chain)
	assert_eq(result.warnings.size(), 1)
	assert_false(result.bakeable)

func test_graph_seed_changes_rendered_frames() -> void:
	var a := _chain(RendererContract.PIXEL_CPU, 111)
	var b := _chain(RendererContract.PIXEL_CPU, 222)
	var first := VFXPipeline.render(_request({"nodes": a.nodes, "connections": a.connections}))
	var second := VFXPipeline.render(_request({"nodes": b.nodes, "connections": b.connections}))
	assert_eq(first.parameters.seed, 111)
	assert_eq(second.parameters.seed, 222)
	assert_ne(first.frames[0].pixels, second.frames[0].pixels)

func test_graph_radius_changes_rendered_frames() -> void:
	var small := _chain(RendererContract.PIXEL_CPU, 391822, 3)
	var large := _chain(RendererContract.PIXEL_CPU, 391822, 15)
	var first := VFXPipeline.render(_request({"nodes": small.nodes, "connections": small.connections}))
	var second := VFXPipeline.render(_request({"nodes": large.nodes, "connections": large.connections}))
	assert_eq(first.parameters.radius, 3)
	assert_eq(second.parameters.radius, 15)
	assert_ne(first.frames[0].pixels, second.frames[0].pixels)

func _opaque_count(canvas: PixelCanvas) -> int:
	var count := 0
	for color in canvas.pixels:
		if color.a > 0.0:
			count += 1
	return count

func test_mask_node_alters_frame_output() -> void:
	var plain := VFXPipeline.render(_request())
	var masked_chain := _chain(RendererContract.PIXEL_CPU, 391822, 10, [{"name": "Mask", "parameters": {"mode": "Radial", "amount": 0.35}}])
	var masked := VFXPipeline.render(_request({"nodes": masked_chain.nodes, "connections": masked_chain.connections}))
	assert_false(bool(plain.parameters.has_mask))
	assert_true(bool(masked.parameters.has_mask))
	assert_eq(String(masked.parameters.mask_mode), "Radial")
	assert_eq(float(masked.parameters.mask_amount), 0.35)
	assert_true(_opaque_count(masked.frames[0]) < _opaque_count(plain.frames[0]))

func test_pixelize_node_controls_output_resolution() -> void:
	var with_pixelize := VFXPipeline.render(_request())
	var chain := _chain()
	var without: Array = []
	for node in chain.nodes:
		if String(node.name) != "Pixelize":
			without.append(node)
	var no_pixelize := VFXPipeline.render(_request({"nodes": without, "connections": []}))
	assert_true(bool(with_pixelize.parameters.has_pixelize))
	assert_false(bool(no_pixelize.parameters.has_pixelize))
	assert_eq(int(with_pixelize.parameters.resolution), 32)

func test_pipeline_output_is_deterministic() -> void:
	var first := VFXPipeline.render(_request())
	var second := VFXPipeline.render(_request())
	assert_eq(first.frames.size(), 4)
	for index in first.frames.size():
		assert_eq(first.frames[index].pixels, second.frames[index].pixels)

func test_preset_selection_changes_frame_output() -> void:
	var impact := VFXPipeline.render(_request({"preset_name": "Impact"}))
	var fireball := VFXPipeline.render(_request({"preset_name": "Fireball Projectile"}))
	assert_eq(impact.frames.size(), 4)
	assert_eq(fireball.frames.size(), 4)
	assert_ne(impact.frames[0].pixels, fireball.frames[0].pixels)

func test_glow_impact_preset_glows_under_pixel_cpu() -> void:
	var chain := _chain(RendererContract.PIXEL_CPU)
	var result := VFXPipeline.render(_request({
		"preset_name": "Glow Impact",
		"nodes": chain.nodes,
		"connections": chain.connections,
	}))
	assert_true(result.glow)
	assert_eq(result.renderer, RendererContract.PIXEL_CPU)

func test_valid_chain_reported_for_standard_chain() -> void:
	var chain := _chain()
	var valid := VFXPipeline.render(_request({"nodes": chain.nodes, "connections": chain.connections}))
	assert_true(valid.valid_chain)
	var rewired := VFXPipeline.render(_request({"nodes": chain.nodes, "connections": []}))
	assert_false(rewired.valid_chain)
	assert_eq(rewired.parameters.seed, int(VFXPipeline.render(_request()).parameters.seed))

func test_frame_count_is_at_least_one() -> void:
	var result := VFXPipeline.render(_request({"frame_count": 0}))
	assert_eq(result.frames.size(), 1)

func test_bakeable_renderer_reports_no_warning() -> void:
	var chain := _chain(RendererContract.CPU_PARTICLES)
	var result := VFXPipeline.render(_request({"nodes": chain.nodes, "connections": chain.connections}))
	assert_eq(result.warnings.size(), 0)
	assert_true(result.bakeable)
	assert_true(result.deterministic)