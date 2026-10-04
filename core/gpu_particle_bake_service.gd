class_name GpuParticleBakeService
extends RefCounted

const SubViewportBaker = preload("res://core/subviewport_baker.gd")

## Creates an isolated GPU particle scene suitable for deterministic export
## capture. The returned images retain transparent backgrounds.
func bake_burst(parent: Node, viewport_size: Vector2i, frame_count: int, frames_per_second: float, color: Color = Color.WHITE) -> Array[Image]:
	var viewport := SubViewport.new()
	viewport.size = viewport_size
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.disable_3d = true
	parent.add_child(viewport)
	var particles := GPUParticles2D.new()
	particles.amount = 96
	particles.lifetime = 0.7
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.randomness = 0.0
	particles.position = Vector2(viewport_size) * 0.5
	particles.visibility_rect = Rect2(Vector2.ZERO, Vector2(viewport_size))
	var process_material := ParticleProcessMaterial.new()
	process_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_POINT
	process_material.direction = Vector3(0, -1, 0)
	process_material.spread = 180.0
	process_material.initial_velocity_min = 70.0
	process_material.initial_velocity_max = 180.0
	process_material.gravity = Vector3(0, 80, 0)
	process_material.scale_min = 0.5
	process_material.scale_max = 1.0
	process_material.color = color
	particles.process_material = process_material
	var particle_image := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	particle_image.fill(Color.WHITE)
	particles.texture = ImageTexture.create_from_image(particle_image)
	viewport.add_child(particles)
	particles.emitting = true
	var baker := SubViewportBaker.new()
	var images := await baker.capture(viewport, frame_count, frames_per_second)
	viewport.queue_free()
	return images
