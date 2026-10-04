class_name GraphEditor
extends Control

signal graph_changed(node_order: Array[String], connection_count: int)
signal node_selected(node_type: String, parameters: Dictionary)
signal palette_load_requested
signal graph_notice(message: String)

const ACCENT := Color("#78ffd9")
const NODE_BG := Color("#20242b")
const NODE_BORDER := Color("#3b4b51")
const NODE_HEADER_BG := Color("#171b20")
const PORT_INPUT := Color("#8aa4ff")
const PORT_OUTPUT := Color("#78ffd9")
const SOCKET_COLORS := {
	"frame": Color("#78ffd9"),
	"scalar": Color("#b69cff"),
	"vector": Color("#78ffd9"),
	"trigger": Color("#ff9b6a"),
	"palette": Color("#f7d774"),
	"particles": Color("#76b9ff"),
	"shader": Color("#ff78c8"),
	"mask": Color("#d0a7ff"),
}
var nodes: Array[Dictionary] = [
	{"name": "Seed", "position": Vector2(40, 50), "inputs": [], "outputs": ["scalar", "trigger"], "parameters": {"seed": 391822, "use_global_seed": true}},
	{"name": "Burst", "position": Vector2(190, 50), "inputs": ["scalar"], "outputs": ["frame", "particles"], "parameters": {"radius": 10, "intensity": 1.0}},
	{"name": "Pixelize", "position": Vector2(340, 50), "inputs": ["frame"], "outputs": ["frame", "mask"], "parameters": {"resolution": 32}},
	{"name": "Palette", "position": Vector2(490, 50), "inputs": ["frame", "palette"], "outputs": ["frame"], "parameters": {"palette": "Fire"}},
	{"name": "Output", "position": Vector2(640, 50), "inputs": ["frame", "particles", "shader"], "outputs": [], "parameters": {"format": "SpriteFrames", "renderer": "Pixel CPU"}},
]
var dragging_index := -1
var drag_offset := Vector2.ZERO
var selected_index := -1
var connections: Array[Dictionary] = [
	{"from": 0, "from_port": 0, "to": 1, "to_port": 0},
	{"from": 1, "from_port": 0, "to": 2, "to_port": 0},
	{"from": 2, "from_port": 0, "to": 3, "to_port": 0},
	{"from": 3, "from_port": 0, "to": 4, "to_port": 0},
]
var connecting_index := -1
var connecting_port := 0
var connection_position := Vector2.ZERO
var graph_zoom := 1.0
var graph_pan := Vector2.ZERO
var panning := false
var pan_anchor := Vector2.ZERO
var show_zoom_indicator := true
var node_controls: Dictionary = {}
var history: Array[Dictionary] = []
var history_index := -1
var suppress_history := false
const NODE_SIZE := Vector2(155, 150)
const GRID_SIZE := 24.0

func _ready() -> void:
	mouse_default_cursor_shape = Control.CURSOR_ARROW
	clip_contents = true
	focus_mode = Control.FOCUS_ALL
	_build_inline_controls()
	_push_history()
	queue_redraw()

func add_registered_node(node_name: String) -> void:
	var definitions := {
		"Scalar Math": {"inputs": ["scalar", "scalar"], "outputs": ["scalar"], "parameters": {"operation": "add"}},
		"Vector Math": {"inputs": ["vector", "vector"], "outputs": ["vector"], "parameters": {"operation": "add"}},
		"Noise Field": {"inputs": ["vector"], "outputs": ["scalar"], "parameters": {"scale": 1.0}},
		"GPU Particles": {"inputs": ["frame"], "outputs": ["particles"], "parameters": {"renderer": "GPU Particles"}},
		"CPU Particles": {"inputs": ["frame"], "outputs": ["particles"], "parameters": {"renderer": "CPU Particles"}},
		"Shader": {"inputs": ["frame"], "outputs": ["shader"], "parameters": {"renderer": "Shader"}},
		"Mask": {"inputs": ["frame"], "outputs": ["mask"], "parameters": {"mode": "Radial", "amount": 1.0}},
		"Texture": {"inputs": ["frame"], "outputs": ["frame"], "parameters": {"path": ""}},
	}
	if not definitions.has(node_name):
		return
	var definition: Dictionary = definitions[node_name]
	var offset := Vector2(80 + nodes.size() * 24, 220 + nodes.size() * 16)
	nodes.append({"name": node_name, "position": offset, "inputs": definition.inputs, "outputs": definition.outputs, "parameters": definition.parameters.duplicate(true)})
	_rebuild_inline_controls()
	_push_history()
	_emit_graph_changed()
	queue_redraw()

func add_custom_node(definition: Dictionary) -> void:
	var node_name := String(definition.get("name", "Custom Node"))
	var offset := Vector2(80 + nodes.size() * 24, 220 + nodes.size() * 16)
	nodes.append({
		"name": node_name,
		"category": String(definition.get("category", "Custom")),
		"description": String(definition.get("description", "")),
		"position": offset,
		"inputs": definition.get("inputs", []),
		"outputs": definition.get("outputs", []),
		"parameters": definition.get("parameters", {}).duplicate(true),
	})
	_rebuild_inline_controls()
	_push_history()
	_emit_graph_changed()
	queue_redraw()

static func remove_node_from_graph(source_nodes: Array, source_connections: Array, index: int) -> Dictionary:
	var result_nodes: Array = source_nodes.duplicate(true)
	var result_connections: Array = []
	if index < 0 or index >= result_nodes.size():
		return {"nodes": result_nodes, "connections": source_connections.duplicate(true), "removed": false}
	result_nodes.remove_at(index)
	for connection in source_connections:
		var from_index := int(connection.get("from", -1))
		var to_index := int(connection.get("to", -1))
		if from_index == index or to_index == index:
			continue
		var remapped: Dictionary = connection.duplicate(true)
		if from_index > index:
			remapped["from"] = from_index - 1
		if to_index > index:
			remapped["to"] = to_index - 1
		result_connections.append(remapped)
	return {"nodes": result_nodes, "connections": result_connections, "removed": true}

static func socket_color(port_type: String) -> Color:
	return SOCKET_COLORS.get(port_type, Color("#9aa7ff"))

func _delete_selected_node() -> void:
	if selected_index < 0 or selected_index >= nodes.size():
		graph_notice.emit("Select a node to delete")
		return
	var removed_name := String(nodes[selected_index].get("name", "Node"))
	var result := remove_node_from_graph(nodes, connections, selected_index)
	nodes.clear()
	for restored_node in result.get("nodes", []):
		if restored_node is Dictionary:
			nodes.append(restored_node)
	connections.clear()
	for restored_connection in result.get("connections", []):
		if restored_connection is Dictionary:
			connections.append(restored_connection)
	selected_index = -1
	dragging_index = -1
	_rebuild_inline_controls()
	_push_history()
	_emit_graph_changed()
	graph_notice.emit("Deleted node | %s" % removed_name)
	queue_redraw()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode == KEY_F:
		_fit_to_view()
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_0:
		_reset_view()
		get_viewport().set_input_as_handled()

func _build_inline_controls() -> void:
	for index in nodes.size():
		var node_name := String(nodes[index].get("name", ""))
		var controls: Array[Control] = []
		match node_name:
			"Seed":
				var seed_edit := LineEdit.new()
				seed_edit.text = str(nodes[index].parameters.get("seed", 0))
				seed_edit.custom_minimum_size = Vector2(129, 22)
				seed_edit.text_submitted.connect(func(value: String) -> void:
					if value.is_valid_int():
						update_node_parameter("Seed", "seed", value.to_int())
				)
				controls.append(seed_edit)
				var randomize_seed := Button.new()
				randomize_seed.text = "Randomize"
				randomize_seed.custom_minimum_size = Vector2(129, 22)
				randomize_seed.pressed.connect(func() -> void:
					var value := randi()
					seed_edit.text = str(value)
					update_node_parameter("Seed", "seed", value)
				)
				controls.append(randomize_seed)
				var use_global := CheckButton.new()
				use_global.text = "Use Global"
				use_global.button_pressed = bool(nodes[index].parameters.get("use_global_seed", true))
				use_global.custom_minimum_size = Vector2(129, 22)
				use_global.toggled.connect(func(enabled: bool) -> void:
					update_node_parameter("Seed", "use_global_seed", enabled)
				)
				controls.append(use_global)
			"Burst":
				controls.append(_make_inline_slider(index, "radius", 2.0, 16.0, 1.0))
				controls.append(_make_inline_slider(index, "intensity", 0.1, 2.0, 0.1))
			"Pixelize":
				var resolution := OptionButton.new()
				for value in [16, 32, 64, 128]:
					resolution.add_item(str(value))
				resolution.select([16, 32, 64, 128].find(int(nodes[index].parameters.get("resolution", 32))))
				resolution.custom_minimum_size = Vector2(129, 22)
				resolution.item_selected.connect(func(option: int) -> void:
					update_node_parameter("Pixelize", "resolution", int(resolution.get_item_text(option)))
				)
				controls.append(resolution)
			"Palette":
				var palette := OptionButton.new()
				palette.add_item("Fire")
				palette.add_item("Ice")
				palette.select(1 if String(nodes[index].parameters.get("palette", "Fire")) == "Ice" else 0)
				palette.custom_minimum_size = Vector2(129, 22)
				palette.item_selected.connect(func(option: int) -> void:
					update_node_parameter("Palette", "palette", palette.get_item_text(option))
				)
				controls.append(palette)
				var load_button := Button.new()
				load_button.text = "Load PNG..."
				load_button.custom_minimum_size = Vector2(129, 22)
				load_button.pressed.connect(func() -> void: palette_load_requested.emit())
				controls.append(load_button)
			"Output":
				var output := OptionButton.new()
				for format in ["PNG", "SpriteSheet", "SpriteFrames"]:
					output.add_item(format)
				output.select(maxi(0, ["PNG", "SpriteSheet", "SpriteFrames"].find(String(nodes[index].parameters.get("format", "SpriteFrames")))))
				output.custom_minimum_size = Vector2(129, 22)
				output.item_selected.connect(func(option: int) -> void:
					update_node_parameter("Output", "format", output.get_item_text(option))
				)
				controls.append(output)
				var renderer := OptionButton.new()
				for mode in ["Pixel CPU", "GPU Particles", "CPU Particles", "Shader", "Hybrid"]:
					renderer.add_item(mode)
				renderer.select(maxi(0, ["Pixel CPU", "GPU Particles", "CPU Particles", "Shader", "Hybrid"].find(String(nodes[index].parameters.get("renderer", "Pixel CPU")))))
				renderer.custom_minimum_size = Vector2(129, 22)
				renderer.item_selected.connect(func(option: int) -> void:
					update_node_parameter("Output", "renderer", renderer.get_item_text(option))
				)
				controls.append(renderer)
		for control in controls:
			control.mouse_filter = Control.MOUSE_FILTER_PASS
			add_child(control)
		node_controls[index] = controls
		_position_inline_controls(index)

func _rebuild_inline_controls() -> void:
	for controls in node_controls.values():
		for control in controls:
			if is_instance_valid(control):
				control.free()
	node_controls.clear()
	_build_inline_controls()

func _make_inline_slider(index: int, parameter: String, minimum: float, maximum: float, step: float) -> HSlider:
	var slider := HSlider.new()
	slider.min_value = minimum
	slider.max_value = maximum
	slider.step = step
	slider.value = float(nodes[index].parameters.get(parameter, minimum))
	slider.custom_minimum_size = Vector2(129, 18)
	slider.value_changed.connect(func(value: float) -> void: update_node_parameter(String(nodes[index].name), parameter, value if step < 1.0 else int(value)))
	return slider

func _position_inline_controls(index: int) -> void:
	var controls: Array = node_controls.get(index, [])
	if index < 0 or index >= nodes.size():
		return
	var node_view_position := _world_to_view(nodes[index].position)
	var node_view_rect := Rect2(node_view_position, NODE_SIZE * graph_zoom)
	var graph_rect := Rect2(Vector2.ZERO, size)
	var node_visible := graph_rect.intersects(node_view_rect)
	for control_index in controls.size():
		var control: Control = controls[control_index]
		var desired := _world_to_view(nodes[index].position + Vector2(8, 78 + control_index * 22))
		var max_position := size - control.size
		control.position = Vector2(clampf(desired.x, 0.0, maxf(0.0, max_position.x)), clampf(desired.y, 0.0, maxf(0.0, max_position.y)))
		control.scale = Vector2.ONE
		control.visible = graph_zoom >= 0.8 and node_visible

func _position_all_inline_controls() -> void:
	for index in nodes.size():
		_position_inline_controls(index)

func _world_to_view(world_position: Vector2) -> Vector2:
	return graph_pan + world_position * graph_zoom

func get_graph_state() -> Dictionary:
	return {
		"nodes": nodes.duplicate(true),
		"connections": connections.duplicate(),
	}

func serialize_state() -> Dictionary:
	var serialized_nodes: Array = []
	for node in nodes:
		var saved_node := node.duplicate(true)
		var position: Vector2 = node.get("position", Vector2.ZERO)
		saved_node["position"] = [position.x, position.y]
		serialized_nodes.append(saved_node)
	var serialized_connections: Array = connections.duplicate(true)
	return {"nodes": serialized_nodes, "connections": serialized_connections}

func set_graph_state(state: Dictionary) -> void:
	suppress_history = true
	var saved_nodes = state.get("nodes", [])
	if saved_nodes is Array and not saved_nodes.is_empty():
		nodes.clear()
		for saved_node in saved_nodes:
			if saved_node is Dictionary:
				var restored_node: Dictionary = saved_node.duplicate(true)
				var saved_position = restored_node.get("position", [0, 0])
				if saved_position is Array and saved_position.size() >= 2:
					restored_node["position"] = Vector2(float(saved_position[0]), float(saved_position[1]))
				nodes.append(restored_node)
	var saved_connections = state.get("connections", [])
	if saved_connections is Array:
		connections.clear()
		for saved_connection in saved_connections:
			if saved_connection is Dictionary:
				connections.append({
					"from": int(saved_connection.get("from", 0)),
					"from_port": int(saved_connection.get("from_port", 0)),
					"to": int(saved_connection.get("to", 0)),
					"to_port": int(saved_connection.get("to_port", 0)),
				})
			elif saved_connection is Array and saved_connection.size() >= 2:
				connections.append({"from": int(saved_connection[0]), "from_port": 0, "to": int(saved_connection[1]), "to_port": 0})
	_rebuild_inline_controls()
	queue_redraw()
	_emit_graph_changed()
	if not suppress_history:
		history.clear()
		history_index = -1
		_push_history()
	suppress_history = false

func update_node_parameter(node_name: String, parameter: String, value: Variant) -> void:
	for node in nodes:
		if String(node.get("name", "")) == node_name:
			var parameters: Dictionary = node.get("parameters", {})
			parameters[parameter] = value
			node["parameters"] = parameters
			_emit_graph_changed()
			return

func get_node_parameter(node_name: String, parameter: String, fallback: Variant = null) -> Variant:
	for node in nodes:
		if String(node.get("name", "")) == node_name:
			var parameters: Dictionary = node.get("parameters", {})
			return parameters.get(parameter, fallback)
	return fallback

func set_node_parameter_silent(node_name: String, parameter: String, value: Variant) -> void:
	for index in nodes.size():
		if String(nodes[index].get("name", "")) == node_name:
			var parameters: Dictionary = nodes[index].get("parameters", {})
			parameters[parameter] = value
			nodes[index]["parameters"] = parameters
			if node_name == "Seed" and parameter == "seed":
				var controls: Array = node_controls.get(index, [])
				if not controls.is_empty() and controls[0] is LineEdit:
					controls[0].text = str(value)
				return

func _emit_graph_changed() -> void:
	if not suppress_history:
		_push_history()
	var order: Array[String] = []
	for node in nodes:
		order.append(String(node.get("name", "")))
	graph_changed.emit(order, connections.size())

func _push_history() -> void:
	var snapshot := serialize_state()
	if history_index >= 0 and history[history_index] == snapshot:
		return
	if history_index < history.size() - 1:
		history.resize(history_index + 1)
	history.append(snapshot)
	if history.size() > 80:
		history.pop_front()
	history_index = history.size() - 1

func _undo_graph() -> void:
	if history_index <= 0:
		graph_notice.emit("Nothing to undo")
		return
	history_index -= 1
	suppress_history = true
	set_graph_state(history[history_index])
	suppress_history = false
	graph_notice.emit("Graph undo")

func _redo_graph() -> void:
	if history_index >= history.size() - 1:
		graph_notice.emit("Nothing to redo")
		return
	history_index += 1
	suppress_history = true
	set_graph_state(history[history_index])
	suppress_history = false
	graph_notice.emit("Graph redo")

func _draw() -> void:
	_draw_grid()
	draw_set_transform(graph_pan, 0.0, Vector2.ONE * graph_zoom)
	for connection in connections:
		var start := _output_port_position(int(connection.from), int(connection.from_port))
		var finish := _input_port_position(int(connection.to), int(connection.to_port))
		draw_line(start, finish, Color("#5bc7b1"), 1.5, true)
		draw_circle(start, 3.5, _port_color(String(nodes[int(connection.from)].get("outputs", [])[int(connection.from_port)])))
		draw_circle(finish, 3.5, _port_color(String(nodes[int(connection.to)].get("inputs", [])[int(connection.to_port)])))
	if connecting_index >= 0:
		var start := _output_port_position(connecting_index, connecting_port)
		draw_line(start, connection_position, ACCENT, 1.5, true)
	for index in nodes.size():
		var node: Dictionary = nodes[index]
		var rect := Rect2(node.position, NODE_SIZE)
		var node_color := _node_color(String(node.get("name", "")))
		draw_style_box(_node_style(index == selected_index, node_color), rect)
		draw_rect(Rect2(node.position, Vector2(NODE_SIZE.x, 28)), NODE_HEADER_BG)
		draw_rect(Rect2(node.position, Vector2(NODE_SIZE.x, 3)), node_color)
		draw_circle(node.position + Vector2(12, 15), 4.0, node_color)
		draw_line(node.position + Vector2(8, 70), node.position + Vector2(NODE_SIZE.x - 8, 70), Color("#303941"), 1.0)
		var inputs: Array = node.get("inputs", [])
		for port_index in inputs.size():
			var input_position := _input_port_position(index, port_index)
			draw_circle(input_position, 4.0, _port_color(String(inputs[port_index])))
		var outputs: Array = node.get("outputs", [])
		for port_index in outputs.size():
			var output_position := _output_port_position(index, port_index)
			draw_circle(output_position, 4.0, _port_color(String(outputs[port_index])))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Keep graph typography at a readable 12 px minimum. Positions still follow
	# graph zoom, but glyphs are rendered at a stable screen size to avoid the
	# blurry scaled text seen when zooming in and out.
	var label_size := 12
	for index in nodes.size():
		var node: Dictionary = nodes[index]
		var view_position := _world_to_view(node.position)
		var title_position := (view_position + Vector2(22, 19) * graph_zoom).snapped(Vector2.ONE)
		draw_string(ThemeDB.fallback_font, title_position, String(node.name).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, NODE_SIZE.x * graph_zoom - 30, label_size, Color("#e5efec"))
		var inputs: Array = node.get("inputs", [])
		for port_index in inputs.size():
			var input_position := _world_to_view(node.position + Vector2(0, 40 + port_index * 16))
			draw_string(ThemeDB.fallback_font, (input_position + Vector2(7, 3)).snapped(Vector2.ONE), String(inputs[port_index]), HORIZONTAL_ALIGNMENT_LEFT, 64, label_size, _port_color(String(inputs[port_index])))
		var outputs: Array = node.get("outputs", [])
		for port_index in outputs.size():
			var output_position := _world_to_view(node.position + Vector2(NODE_SIZE.x, 40 + port_index * 16))
			draw_string(ThemeDB.fallback_font, (output_position + Vector2(-70, 3)).snapped(Vector2.ONE), String(outputs[port_index]), HORIZONTAL_ALIGNMENT_RIGHT, 64, label_size, _port_color(String(outputs[port_index])))
	if show_zoom_indicator:
		draw_string(ThemeDB.fallback_font, Vector2(size.x - 72, 22).snapped(Vector2.ONE), "%d%%" % roundi(graph_zoom * 100.0), HORIZONTAL_ALIGNMENT_RIGHT, 66, label_size, Color("#8faaa5"))

func _draw_grid() -> void:
	var step := 24.0 * graph_zoom
	if step < 8.0:
		return
	var origin := Vector2(fposmod(graph_pan.x, step), fposmod(graph_pan.y, step))
	for x in range(int(origin.x), int(size.x), maxi(1, int(step))):
		draw_line(Vector2(x, 0), Vector2(x, size.y), Color("#202830"), 1.0)
	for y in range(int(origin.y), int(size.y), maxi(1, int(step))):
		draw_line(Vector2(0, y), Vector2(size.x, y), Color("#202830"), 1.0)

func _input_port_position(node_index: int, port_index: int) -> Vector2:
	return nodes[node_index].position + Vector2(0, 40 + port_index * 16)

func _output_port_position(node_index: int, port_index: int) -> Vector2:
	return nodes[node_index].position + Vector2(NODE_SIZE.x, 40 + port_index * 16)

func _node_color(node_name: String) -> Color:
	match node_name:
		"Seed": return Color("#78ffd9")
		"Burst": return Color("#ff9b6a")
		"Pixelize": return Color("#b69cff")
		"Palette": return Color("#f7d774")
		"Output": return Color("#76b9ff")
		_: return ACCENT

func _port_color(port_type: String) -> Color:
	return socket_color(port_type)

func _node_style(selected: bool, node_color: Color = ACCENT) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = NODE_BG
	style.border_color = ACCENT if selected else Color(node_color, 0.55)
	style.set_border_width_all(2 if selected else 1)
	style.set_corner_radius_all(6)
	return style

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		grab_focus()
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_DELETE, KEY_BACKSPACE]:
			_delete_selected_node()
			accept_event()
			return
		if event.ctrl_pressed and event.keycode == KEY_Z:
			_undo_graph()
			accept_event()
			return
		if event.ctrl_pressed and event.keycode == KEY_Y:
			_redo_graph()
			accept_event()
			return
		if event.keycode == KEY_F:
			_fit_to_view()
			accept_event()
			return
		if event.keycode == KEY_0:
			_reset_view()
			accept_event()
			return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_MIDDLE:
		panning = event.pressed
		pan_anchor = event.position
		accept_event()
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_UP:
		_set_zoom_at(event.position, minf(2.5, graph_zoom * 1.1))
		accept_event()
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		_set_zoom_at(event.position, maxf(0.35, graph_zoom / 1.1))
		accept_event()
		return
	if event is InputEventMouseMotion and panning:
		graph_pan += event.position - pan_anchor
		pan_anchor = event.position
		_position_all_inline_controls()
		queue_redraw()
		accept_event()
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		var reroute_index := _connection_at((event.position - graph_pan) / graph_zoom)
		if reroute_index >= 0:
			if Input.is_key_pressed(KEY_CTRL):
				connections.remove_at(reroute_index)
				graph_notice.emit("Connection removed")
			else:
				_insert_reroute(reroute_index, (event.position - graph_pan) / graph_zoom)
				graph_notice.emit("Reroute inserted")
			_emit_graph_changed()
			queue_redraw()
			accept_event()
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var world_position: Vector2 = (event.position - graph_pan) / graph_zoom
		if event.pressed:
			var cable_index := _connection_at(world_position)
			if cable_index >= 0:
				var cable: Dictionary = connections[cable_index]
				connecting_index = int(cable.get("from", -1))
				connecting_port = int(cable.get("from_port", 0))
				connections.remove_at(cable_index)
				connection_position = world_position
				graph_notice.emit("Reconnect cable")
				accept_event()
				queue_redraw()
				return
			for index in range(nodes.size() - 1, -1, -1):
				for port_index in nodes[index].get("outputs", []).size():
					var output_port := _output_port_position(index, port_index)
					if output_port.distance_to(world_position) <= 10.0 / graph_zoom:
						connecting_index = index
						connecting_port = port_index
						connection_position = world_position
						accept_event()
						queue_redraw()
						return
			for index in range(nodes.size() - 1, -1, -1):
				if Rect2(nodes[index].position, NODE_SIZE).has_point(world_position):
					selected_index = index
					node_selected.emit(nodes[index].name, nodes[index].parameters)
					dragging_index = index
					drag_offset = world_position - nodes[index].position
					queue_redraw()
					accept_event()
					return
		else:
			if connecting_index >= 0:
				for index in range(nodes.size() - 1, -1, -1):
					for port_index in nodes[index].get("inputs", []).size():
						var input_port := _input_port_position(index, port_index)
						if input_port.distance_to(world_position) > 10.0 / graph_zoom:
							continue
						var edge := {"from": connecting_index, "from_port": connecting_port, "to": index, "to_port": port_index}
						if _connection_types_match(connecting_index, index, connecting_port, port_index):
							var replaced := _replace_input_connection(index, port_index)
							if not connections.has(edge):
								connections.append(edge)
							_emit_graph_changed()
							graph_notice.emit("Connection replaced" if replaced else "Connection added")
						elif not _connection_types_match(connecting_index, index, connecting_port, port_index):
							graph_notice.emit("Connection rejected: incompatible port types")
						break
				connecting_index = -1
				queue_redraw()
				accept_event()
				return
			if dragging_index >= 0:
				_emit_graph_changed()
			dragging_index = -1
	elif event is InputEventMouseMotion and dragging_index >= 0:
		var next_position: Vector2 = (event.position - graph_pan) / graph_zoom - drag_offset
		nodes[dragging_index].position = Vector2(roundf(next_position.x / GRID_SIZE) * GRID_SIZE, roundf(next_position.y / GRID_SIZE) * GRID_SIZE)
		_position_inline_controls(dragging_index)
		queue_redraw()
		accept_event()
	elif event is InputEventMouseMotion and connecting_index >= 0:
		connection_position = (event.position - graph_pan) / graph_zoom
		queue_redraw()
		accept_event()

func _connection_types_match(from_index: int, to_index: int, from_port: int = 0, to_port: int = 0) -> bool:
	var from_outputs: Array = nodes[from_index].get("outputs", [])
	var to_inputs: Array = nodes[to_index].get("inputs", [])
	if from_port >= from_outputs.size() or to_port >= to_inputs.size():
		return false
	return String(from_outputs[from_port]) == String(to_inputs[to_port])

func _replace_input_connection(to_index: int, to_port: int) -> bool:
	var replaced := false
	for connection_index in range(connections.size() - 1, -1, -1):
		var connection: Dictionary = connections[connection_index]
		if int(connection.get("to", -1)) == to_index and int(connection.get("to_port", -1)) == to_port:
			connections.remove_at(connection_index)
			replaced = true
	return replaced

func _insert_reroute(connection_index: int, world_position: Vector2) -> void:
	var cable: Dictionary = connections[connection_index]
	var from_index := int(cable.get("from", -1))
	var from_port := int(cable.get("from_port", 0))
	var to_index := int(cable.get("to", -1))
	var to_port := int(cable.get("to_port", 0))
	var port_type := String(nodes[from_index].get("outputs", [])[from_port])
	var reroute := {"name": "Reroute", "position": world_position - Vector2(40, 50), "inputs": [port_type], "outputs": [port_type], "parameters": {"type": port_type}}
	var new_index := nodes.size()
	nodes.append(reroute)
	connections.remove_at(connection_index)
	connections.append({"from": from_index, "from_port": from_port, "to": new_index, "to_port": 0})
	connections.append({"from": new_index, "from_port": 0, "to": to_index, "to_port": to_port})
	node_controls[new_index] = []

func _connection_at(position: Vector2) -> int:
	for index in connections.size():
		var connection := connections[index]
		var start := _output_port_position(int(connection.from), int(connection.from_port))
		var finish := _input_port_position(int(connection.to), int(connection.to_port))
		if Geometry2D.get_closest_point_to_segment(position, start, finish).distance_to(position) <= 6.0:
			return index
	return -1

func _set_zoom_at(view_position: Vector2, new_zoom: float) -> void:
	var world_before := (view_position - graph_pan) / graph_zoom
	graph_zoom = new_zoom
	graph_pan = view_position - world_before * graph_zoom
	_position_all_inline_controls()
	queue_redraw()

func _reset_view() -> void:
	graph_zoom = 1.0
	graph_pan = Vector2.ZERO
	_position_all_inline_controls()
	queue_redraw()
	graph_notice.emit("Graph view reset")

func _fit_to_view() -> void:
	if nodes.is_empty():
		_reset_view()
		return
	var bounds := Rect2(nodes[0].position, NODE_SIZE)
	for node in nodes:
		bounds = bounds.merge(Rect2(node.position, NODE_SIZE))
	var margin := 48.0
	var available := size - Vector2(margin * 2.0, margin * 2.0)
	if available.x <= 0.0 or available.y <= 0.0:
		return
	graph_zoom = clampf(minf(available.x / bounds.size.x, available.y / bounds.size.y), 0.35, 2.5)
	graph_pan = (size - bounds.size * graph_zoom) * 0.5 - bounds.position * graph_zoom
	_position_all_inline_controls()
	queue_redraw()
	graph_notice.emit("Graph fitted to view")
