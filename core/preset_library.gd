class_name PresetLibrary
extends RefCounted

static func builtins() -> Array[Dictionary]:
	return [
		{"name": "Impact", "generator": "impact", "renderer": "Pixel CPU", "parameters": {"radius": 10, "intensity": 1.0}, "description": "Deterministic radial impact burst."},
		{"name": "Slash", "generator": "slash", "renderer": "Pixel CPU", "parameters": {"length": 18, "angle": -0.6}, "description": "Directional arc slash."},
		{"name": "Explosion", "generator": "explosion", "renderer": "Hybrid", "parameters": {"radius": 18, "intensity": 1.4}, "description": "Layered explosion with particle preview."},
		{"name": "Projectile", "generator": "projectile", "renderer": "Pixel CPU", "recipe": ["Head", "Trail", "Output"], "parameters": {"length": 12, "trail": 0.8}, "description": "Fast projectile: bright head with a tapered trailing path."},
		{"name": "Fireball Projectile", "generator": "projectile", "renderer": "Hybrid", "recipe": ["Core", "Trail", "Glow", "Output"], "parameters": {"length": 18, "trail": 1.0, "glow": 0.8}, "description": "Production projectile with fireball head, animated trail, and glow."},
		{"name": "Fire", "generator": "fire", "renderer": "Hybrid", "parameters": {"radius": 12, "turbulence": 0.7}, "description": "Animated fire plume."},
		{"name": "Lightning", "generator": "lightning", "renderer": "Shader", "parameters": {"branches": 4, "jitter": 0.5}, "description": "Branching lightning stroke."},
		{"name": "Lightning Sideways", "generator": "lightning", "renderer": "Hybrid", "recipe": ["Bolt", "Glow", "Output"], "parameters": {"direction": "sideways", "jitter": 0.5}, "description": "Horizontal lightning projectile or beam."},
		{"name": "Lightning Downward", "generator": "lightning", "renderer": "Hybrid", "recipe": ["Bolt", "Glow", "Output"], "parameters": {"direction": "downward", "jitter": 0.5}, "description": "Vertical lightning strike from above."},
		{"name": "Smoke", "generator": "smoke", "renderer": "CPU Particles", "parameters": {"radius": 14, "drag": 0.9}, "description": "Soft seeded smoke motion."},
		{"name": "Magic", "generator": "magic", "renderer": "Hybrid", "parameters": {"radius": 16, "orbit": 1.0}, "description": "Orbiting magical energy."},
		{"name": "Spark Burst", "generator": "particles", "renderer": "CPU Particles", "recipe": ["Burst", "Sparks", "Output"], "parameters": {"count": 48, "spread": 3.14}, "description": "Short-lived spark burst for impact contact points."},
		{"name": "AOE Attack", "generator": "explosion", "renderer": "Hybrid", "recipe": ["Core", "Ring", "Sparks", "Output"], "parameters": {"radius": 18, "intensity": 1.2}, "description": "Area attack: expanding core, readable ring, and outward sparks."},
		{"name": "Glow Impact", "generator": "impact", "renderer": "Hybrid", "parameters": {"radius": 10, "intensity": 1.0}, "description": "Pixel impact with GPU glow preview."},
	]

static func find(name: String) -> Dictionary:
	for preset in builtins():
		if String(preset.name) == name:
			return preset
	return {}

static func graph_for(name: String) -> Dictionary:
	var stage_names: Array = []
	match name:
		"Projectile": stage_names = ["Seed", "Head", "Trail", "Output"]
		"Fireball Projectile": stage_names = ["Seed", "Core", "Trail", "Glow", "Output"]
		"Spark Burst": stage_names = ["Seed", "Burst", "Sparks", "Output"]
		"AOE Attack": stage_names = ["Seed", "Core", "Ring", "Sparks", "Output"]
		"Lightning Sideways", "Lightning Downward": stage_names = ["Seed", "Bolt", "Glow", "Output"]
		_: stage_names = ["Seed", "Burst", "Pixelize", "Palette", "Output"]
	var graph_nodes: Array[Dictionary] = []
	for index in stage_names.size():
		var stage: String = String(stage_names[index])
		var inputs: Array[String] = []
		if index != 0:
			inputs.append("frame")
		var outputs: Array = ["frame"] if stage != "Output" else []
		if stage == "Seed":
			outputs = ["scalar"]
		elif index == 1:
			inputs = ["scalar"]
		elif stage == "Output":
			inputs = ["frame"]
		graph_nodes.append({"name": stage, "position": Vector2(40 + index * 170, 80), "inputs": inputs, "outputs": outputs, "parameters": {}})
	var graph_connections: Array[Dictionary] = []
	for index in range(graph_nodes.size() - 1):
		graph_connections.append({"from": index, "from_port": 0, "to": index + 1, "to_port": 0})
	return {"nodes": graph_nodes, "connections": graph_connections}

static func file_slug(name: String) -> String:
	return name.to_lower().replace(" ", "_")
