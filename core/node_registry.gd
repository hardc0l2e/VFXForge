class_name NodeRegistry
extends RefCounted

static func all() -> Array[Dictionary]:
	return [
		{"name": "Seed", "category": "Generators", "kind": "source"},
		{"name": "Burst", "category": "Generators", "kind": "effect"},
		{"name": "Scalar Math", "category": "Math", "kind": "field"},
		{"name": "Vector Math", "category": "Math", "kind": "field"},
		{"name": "Noise Field", "category": "Fields", "kind": "field"},
		{"name": "Pixelize", "category": "Pixel", "kind": "filter"},
		{"name": "Palette", "category": "Color", "kind": "filter"},
		{"name": "GPU Particles", "category": "Particles", "kind": "renderer"},
		{"name": "CPU Particles", "category": "Particles", "kind": "renderer"},
		{"name": "Shader", "category": "Shaders", "kind": "renderer"},
		{"name": "Output", "category": "Output", "kind": "sink"},
	]

static func search(query: String) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	var needle := query.strip_edges().to_lower()
	for node in all():
		if needle.is_empty() or String(node.name).to_lower().contains(needle) or String(node.category).to_lower().contains(needle):
			results.append(node)
	return results
