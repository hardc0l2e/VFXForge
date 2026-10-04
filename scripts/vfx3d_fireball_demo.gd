extends Node3D

const VFXBakeProfile = preload("res://core/vfx_bake_profile.gd")

var profile := VFXBakeProfile.new()
var fireball: GPUParticles3D
var trail: GPUParticles3D
var core: MeshInstance3D
var glow: MeshInstance3D
var time := 0.0

func _ready() -> void:
	profile.resolution = Vector2i(256, 256)
	profile.frame_count = 24
	profile.orthographic_scale = 4.0
	_build_scene()
	_restart_effect()

func _build_scene() -> void:
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = profile.orthographic_scale
	camera.position = Vector3(0, 0, 8)
	camera.look_at_from_position(camera.position, Vector3.ZERO)
	add_child(camera)
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.015, 0.02, 0.025, 1.0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.12, 0.2, 0.2)
	env.ambient_light_energy = 0.7
	environment.environment = env
	add_child(environment)
	core = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.65
	sphere.height = 1.3
	core.mesh = sphere
	var material := ShaderMaterial.new()
	var core_shader := Shader.new()
	core_shader.code = "shader_type spatial; render_mode unshaded; uniform vec4 core_color : source_color = vec4(0.47, 1.0, 0.85, 1.0); uniform float distortion = 0.12; void fragment(){ vec2 p = UV - vec2(0.5); float wave = sin((p.x + p.y) * 28.0 + TIME * 7.0) * distortion; float edge = smoothstep(0.5, 0.18, length(p) + wave); ALBEDO = core_color.rgb; EMISSION = core_color.rgb * (2.0 + edge * 3.0); ALPHA = edge; }"
	material.shader = core_shader
	material.set_shader_parameter("core_color", Color("#78ffd9"))
	core.material_override = material
	add_child(core)
	glow = MeshInstance3D.new()
	var glow_sphere := SphereMesh.new()
	glow_sphere.radius = 0.95
	glow_sphere.height = 1.9
	glow.mesh = glow_sphere
	var glow_material := StandardMaterial3D.new()
	glow_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	glow_material.albedo_color = Color(0.47, 1.0, 0.85, 0.12)
	glow_material.emission_enabled = true
	glow_material.emission = Color("#78ffd9")
	glow_material.emission_energy_multiplier = 2.5
	glow.material_override = glow_material
	add_child(glow)
	fireball = GPUParticles3D.new()
	fireball.amount = 96
	fireball.lifetime = 0.65
	fireball.one_shot = false
	fireball.local_coords = false
	fireball.visibility_aabb = AABB(Vector3(-4, -4, -4), Vector3(8, 8, 8))
	var particle_material := ParticleProcessMaterial.new()
	particle_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	particle_material.emission_sphere_radius = 0.5
	particle_material.direction = Vector3(0, 0, -1)
	particle_material.spread = 35.0
	particle_material.initial_velocity_min = 1.5
	particle_material.initial_velocity_max = 3.5
	particle_material.gravity = Vector3(0, 0, 0)
	particle_material.scale_min = 0.08
	particle_material.scale_max = 0.22
	particle_material.color = Color("#ff9b6a")
	fireball.process_material = particle_material
	var quad := QuadMesh.new()
	quad.size = Vector2(0.18, 0.18)
	var particle_shader := Shader.new()
	particle_shader.code = "shader_type spatial; render_mode unshaded, cull_disabled, depth_draw_never; uniform vec4 tint : source_color = vec4(1.0); void fragment(){ float d = distance(UV, vec2(0.5)); float a = smoothstep(0.5, 0.05, d); ALBEDO = tint.rgb; EMISSION = tint.rgb * 2.0; ALPHA = a * tint.a; }"
	var particle_material_override := ShaderMaterial.new()
	particle_material_override.shader = particle_shader
	particle_material_override.set_shader_parameter("tint", Color("#ff9b6a"))
	quad.material = particle_material_override
	fireball.draw_pass_1 = quad
	add_child(fireball)
	trail = GPUParticles3D.new()
	trail.amount = 72
	trail.lifetime = 0.9
	trail.local_coords = false
	trail.visibility_aabb = AABB(Vector3(-5, -5, -5), Vector3(10, 10, 10))
	var trail_material := ParticleProcessMaterial.new()
	trail_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	trail_material.emission_sphere_radius = 0.35
	trail_material.direction = Vector3(0, 0, 1)
	trail_material.spread = 18.0
	trail_material.initial_velocity_min = 0.8
	trail_material.initial_velocity_max = 2.0
	trail_material.gravity = Vector3(0, 0, 0)
	trail_material.scale_min = 0.05
	trail_material.scale_max = 0.16
	trail_material.color = Color("#ff9b6a")
	trail.process_material = trail_material
	trail.draw_pass_1 = quad
	add_child(trail)

func _process(delta: float) -> void:
	time += delta
	if core != null:
		core.scale = Vector3.ONE * (1.0 + sin(time * 8.0) * 0.08)
		core.rotation.y = time * 1.5
	if glow != null:
		glow.scale = Vector3.ONE * (1.0 + sin(time * 5.0) * 0.12)

func _restart_effect() -> void:
	if fireball != null:
		fireball.restart()
	if trail != null:
		trail.restart()
