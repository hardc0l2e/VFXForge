@tool
extends "res://tests/harness/test_suite.gd"

const GraphEvaluator = preload("res://core/graph_evaluator.gd")
const FieldMath = preload("res://core/field_math.gd")
const NodeRegistry = preload("res://core/node_registry.gd")
const ProceduralFields = preload("res://core/procedural_fields.gd")
const KeyframeTrack = preload("res://core/keyframe_track.gd")
const VectorShapes = preload("res://core/vector_shapes.gd")
const CustomNodeDefinition = preload("res://core/custom_node_definition.gd")
const ParameterAnimation = preload("res://core/parameter_animation.gd")
const CustomNodeLibrary = preload("res://core/custom_node_library.gd")
const CustomNodeRuntime = preload("res://core/custom_node_runtime.gd")
const GraphEditor = preload("res://editor/graph_editor.gd")
const PlaybackClock = preload("res://core/playback_clock.gd")

func suite_name() -> String:
	return "graph"

func test_evaluate_reads_graph_parameters() -> void:
	var nodes: Array[Dictionary] = [
		{"name": "Seed", "parameters": {"seed": 12}},
		{"name": "Burst", "parameters": {"radius": 6, "intensity": 0.5}},
		{"name": "Pixelize", "parameters": {"resolution": 16}},
		{"name": "Palette", "parameters": {"palette": "Ice"}},
		{"name": "Output", "parameters": {"format": "PNG", "renderer": "CPU Particles"}},
	]
	var edges: Array[Vector2i] = [Vector2i(0, 1), Vector2i(1, 2), Vector2i(2, 3), Vector2i(3, 4)]
	var result := GraphEvaluator.evaluate(nodes, edges)
	assert_true(result.valid)
	assert_eq(result.seed, 12)
	assert_eq(result.radius, 6)
	assert_true(is_equal_approx(result.intensity, 0.5))
	assert_eq(result.palette, "Ice")
	assert_eq(result.output, "PNG")
	assert_eq(result.renderer, "CPU Particles")

func test_evaluate_tracks_pixelize_mask_and_texture_nodes() -> void:
	var nodes: Array[Dictionary] = [
		{"name": "Pixelize", "parameters": {"resolution": 64}},
		{"name": "Mask", "parameters": {"mode": "Radial", "amount": 0.5}},
		{"name": "Texture", "parameters": {"path": "res://raw/sample_palette.png"}},
	]
	var result := GraphEvaluator.evaluate(nodes, [])
	assert_true(result.get("has_pixelize", false))
	assert_true(result.get("has_mask", false))
	assert_eq(result.get("resolution"), 64)
	assert_eq(result.get("texture_path"), "res://raw/sample_palette.png")
	assert_eq(result.get("mask_amount"), 0.5)

func test_invalid_chain_is_reported_without_crashing() -> void:
	var nodes: Array[Dictionary] = [
		{"name": "Seed", "parameters": {"seed": 4}},
		{"name": "Burst", "parameters": {"radius": 10, "intensity": 1.0}},
	]
	var empty_edges: Array = []
	var result := GraphEvaluator.evaluate(nodes, empty_edges)
	assert_false(result.valid)
	assert_eq(result.seed, 4)

func test_field_math_supports_scalar_and_vector_operations() -> void:
	assert_eq(FieldMath.scalar("multiply", 3.0, 4.0), 12.0)
	assert_eq(FieldMath.vector("add", Vector2(1, 2), Vector2(3, 4)), Vector2(4, 6))
	assert_true(is_equal_approx(FieldMath.remap(5.0, 0.0, 10.0, 0.0, 1.0), 0.5))

func test_node_registry_searches_geometry_style_nodes() -> void:
	var results := NodeRegistry.search("vector")
	assert_eq(results.size(), 1)
	assert_eq(results[0].get("category"), "Math")

func test_procedural_fields_are_seed_deterministic() -> void:
	var first := ProceduralFields.noise_2d(Vector2(0.25, 0.75), 42, 2.0)
	var second := ProceduralFields.noise_2d(Vector2(0.25, 0.75), 42, 2.0)
	assert_true(is_equal_approx(first, second))
	assert_true(first >= 0.0 and first <= 1.0)

func test_radial_falloff_is_bounded() -> void:
	assert_eq(ProceduralFields.radial_falloff(Vector2.ZERO, 10.0), 1.0)
	assert_eq(ProceduralFields.radial_falloff(Vector2(20, 0), 10.0), 0.0)

func test_keyframe_track_interpolates_parameters() -> void:
	var track := KeyframeTrack.new()
	track.add_key(0.0, 0.0)
	track.add_key(1.0, 10.0)
	assert_eq(track.sample(0.5), 5.0)
	assert_eq(track.sample(2.0), 10.0)

func test_vector_shapes_sample_bezier_endpoints() -> void:
	var points := VectorShapes.bezier_points(Vector2.ZERO, Vector2(1, 0), Vector2(2, 1), Vector2(3, 1), 8)
	assert_eq(points.size(), 9)
	assert_eq(points[0], Vector2.ZERO)
	assert_eq(points[8], Vector2(3, 1))

func test_custom_node_definition_validates_typed_ports() -> void:
	var definition := CustomNodeDefinition.new("Vector Offset")
	definition.description = "Offsets a vector field"
	definition.add_input("vector").add_output("vector").add_parameter("amount", 1.0)
	assert_true(definition.validate().is_empty())
	assert_eq(definition.serialize().get("name"), "Vector Offset")
	assert_eq(definition.serialize().get("description"), "Offsets a vector field")

func test_custom_node_library_discovers_and_rejects_definitions() -> void:
	var directory := "res://exports/custom_node_test"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	var valid := FileAccess.open(directory + "/valid.json", FileAccess.WRITE)
	valid.store_string(JSON.stringify({"name": "Test Warp", "category": "Fields", "inputs": ["frame"], "outputs": ["frame"], "parameters": {"amount": 1.0}}))
	valid.close()
	var invalid := FileAccess.open(directory + "/invalid.json", FileAccess.WRITE)
	invalid.store_string(JSON.stringify({"name": ""}))
	invalid.close()
	var result := CustomNodeLibrary.load_directory(directory)
	assert_eq(result.nodes.size(), 1)
	assert_eq(result.nodes[0].get("name"), "Test Warp")
	assert_eq(result.errors.size(), 1)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(directory + "/valid.json"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(directory + "/invalid.json"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(directory))

func test_custom_node_runtime_validates_inputs_and_calls_executor() -> void:
	var definition := {"inputs": ["value"], "parameters": {"amount": 2}}
	var result := CustomNodeRuntime.execute(definition, {"value": 3}, {}, func(inputs: Dictionary, _context: Dictionary, parameters: Dictionary) -> Dictionary:
		return {"value": inputs.value * parameters.amount}
	)
	assert_true(result.ok)
	assert_eq(result.outputs.value, 6)
	var missing := CustomNodeRuntime.execute(definition, {}, {}, func(_inputs: Dictionary, _context: Dictionary, _parameters: Dictionary) -> Dictionary: return {})
	assert_false(missing.ok)

func test_graph_evaluator_executes_field_nodes() -> void:
	var nodes: Array[Dictionary] = [
		{"name": "Scalar Math", "parameters": {"operation": "multiply", "a": 3.0, "b": 4.0}},
		{"name": "Noise Field", "parameters": {"scale": 1.0, "position": Vector2(0.5, 0.5)}},
	]
	var fields := GraphEvaluator.evaluate_fields(nodes, {"seed": 4})
	assert_eq(fields.size(), 2)
	assert_eq(fields[0].value, 12.0)
	assert_true(float(fields[1].value) >= 0.0 and float(fields[1].value) <= 1.0)

func test_graph_evaluator_reports_renderer_capabilities() -> void:
	var nodes: Array[Dictionary] = [{"name": "CPU Particles", "parameters": {"renderer": "CPU Particles"}}]
	var fields := GraphEvaluator.evaluate_fields(nodes)
	assert_eq(fields[0].renderer, "CPU Particles")
	assert_true(fields[0].capability.deterministic)

func test_graph_socket_colors_are_stable_by_type() -> void:
	var frame := GraphEditor.socket_color("frame")
	var particles := GraphEditor.socket_color("particles")
	assert_eq(frame.to_html(false), "78ffd9")
	assert_eq(particles.to_html(false), "76b9ff")
	assert_eq(GraphEditor.socket_color("frame"), GraphEditor.socket_color("frame"))

func test_graph_node_removal_remaps_connections() -> void:
	var nodes: Array = [{"name": "A"}, {"name": "B"}, {"name": "C"}]
	var connections: Array = [{"from": 0, "from_port": 0, "to": 1, "to_port": 0}, {"from": 1, "from_port": 0, "to": 2, "to_port": 0}]
	var result := GraphEditor.remove_node_from_graph(nodes, connections, 1)
	assert_true(result.removed)
	assert_eq(result.nodes.size(), 2)
	assert_eq(result.connections.size(), 0)

func test_parameter_animation_samples_named_tracks() -> void:
	var animation := ParameterAnimation.new()
	animation.add_key("intensity", 0.0, 0.0)
	animation.add_key("intensity", 1.0, 2.0)
	assert_eq(animation.sample("intensity", 0.5), 1.0)
	assert_eq(animation.sample("missing", 0.5, 4.0), 4.0)

func test_playback_clock_uses_fps_for_frame_steps() -> void:
	var slow := PlaybackClock.advance(0.0, 0.25, 2.0)
	assert_eq(slow.steps, 0)
	var ready := PlaybackClock.advance(slow.accumulator, 0.25, 2.0)
	assert_eq(ready.steps, 1)
	assert_true(is_equal_approx(ready.accumulator, 0.0))
