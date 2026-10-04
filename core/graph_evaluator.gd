class_name GraphEvaluator
extends RefCounted

const FieldMath = preload("res://core/field_math.gd")
const ProceduralFields = preload("res://core/procedural_fields.gd")
const RendererContract = preload("res://core/renderer_contract.gd")

const DEFAULTS := {
	"seed": 391822,
	"radius": 10,
	"intensity": 1.0,
	"palette": "Fire",
	"resolution": 32,
	"output": "SpriteFrames",
	"renderer": "Pixel CPU",
}

static func evaluate(nodes: Array[Dictionary], connections: Array, fallback: Dictionary = {}) -> Dictionary:
	var values: Dictionary = DEFAULTS.duplicate(true)
	for key in fallback:
		values[key] = fallback[key]
	var node_by_name: Dictionary = {}
	for node in nodes:
		var node_name := String(node.get("name", ""))
		if not node_name.is_empty():
			node_by_name[node_name] = node
	values["has_pixelize"] = node_by_name.has("Pixelize")
	values["has_mask"] = node_by_name.has("Mask")
	values["texture_path"] = ""
	var required := ["Seed", "Burst", "Pixelize", "Palette", "Output"]
	for node_name in required:
		if not node_by_name.has(node_name):
			continue
		var parameters: Dictionary = node_by_name[node_name].get("parameters", {})
		match node_name:
			"Seed":
				values["seed"] = int(parameters.get("seed", values["seed"]))
			"Burst":
				values["radius"] = int(parameters.get("radius", values["radius"]))
				values["intensity"] = float(parameters.get("intensity", values["intensity"]))
			"Pixelize":
				values["resolution"] = int(parameters.get("resolution", values["resolution"]))
			"Palette":
				values["palette"] = String(parameters.get("palette", values["palette"]))
			"Output":
				values["output"] = String(parameters.get("format", values["output"]))
				values["renderer"] = String(parameters.get("renderer", values["renderer"]))
	for node in nodes:
		var optional_name := String(node.get("name", ""))
		var optional_parameters: Dictionary = node.get("parameters", {})
		if optional_name == "Mask":
			values["mask_mode"] = String(optional_parameters.get("mode", "Radial"))
			values["mask_amount"] = clampf(float(optional_parameters.get("amount", 1.0)), 0.0, 1.0)
		elif optional_name == "Texture":
			values["texture_path"] = String(optional_parameters.get("path", ""))
	values["fields"] = evaluate_fields(nodes, values)
	values["valid"] = _has_valid_chain(nodes, connections)
	return values

static func evaluate_fields(nodes: Array[Dictionary], context: Dictionary = {}) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	for node in nodes:
		var node_name := String(node.get("name", ""))
		var parameters: Dictionary = node.get("parameters", {})
		match node_name:
			"Scalar Math":
				results.append({"node": node_name, "type": "scalar", "value": FieldMath.scalar(String(parameters.get("operation", "add")), float(parameters.get("a", 0.0)), float(parameters.get("b", 0.0)))})
			"Vector Math":
				results.append({"node": node_name, "type": "vector", "value": FieldMath.vector(String(parameters.get("operation", "add")), parameters.get("a", Vector2.ZERO), parameters.get("b", Vector2.ZERO))})
			"Noise Field":
				results.append({"node": node_name, "type": "scalar", "value": ProceduralFields.noise_2d(parameters.get("position", Vector2.ZERO), int(context.get("seed", 0)), float(parameters.get("scale", 1.0)))})
			"CPU Particles", "GPU Particles", "Shader":
				var renderer_name := String(parameters.get("renderer", node_name))
				results.append({"node": node_name, "type": "renderer", "renderer": renderer_name, "capability": RendererContract.describe(renderer_name)})
	return results

static func _has_valid_chain(nodes: Array[Dictionary], connections: Array) -> bool:
	var index_by_name: Dictionary = {}
	for index in nodes.size():
		index_by_name[String(nodes[index].get("name", ""))] = index
	var expected := ["Seed", "Burst", "Pixelize", "Palette", "Output"]
	for index in range(expected.size() - 1):
		if not index_by_name.has(expected[index]) or not index_by_name.has(expected[index + 1]):
			return false
		if not _has_connection(nodes, connections, index_by_name[expected[index]], index_by_name[expected[index + 1]]):
			return false
	return true

static func _has_connection(nodes: Array[Dictionary], connections: Array, from_index: int, to_index: int) -> bool:
	var pending: Array[int] = [from_index]
	var visited: Dictionary = {}
	while not pending.is_empty():
		var current: int = pending.pop_front()
		if current == to_index:
			return true
		if visited.has(current):
			continue
		visited[current] = true
		for connection in connections:
			var source := -1
			var target := -1
			if connection is Dictionary:
				source = int(connection.get("from", -1))
				target = int(connection.get("to", -1))
			elif connection is Vector2i:
				source = connection.x
				target = connection.y
			elif connection is Array and connection.size() >= 2:
				source = int(connection[0])
				target = int(connection[1])
			if source == current and target >= 0 and target < nodes.size() and not visited.has(target):
				pending.append(target)
	return false
