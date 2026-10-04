class_name CustomNodeDefinition
extends RefCounted

var name := "Custom Node"
var category := "Custom"
var description := ""
var inputs: Array[String] = []
var outputs: Array[String] = []
var parameters: Dictionary = {}

func _init(node_name: String = "Custom Node") -> void:
	name = node_name

func add_input(port_name: String) -> CustomNodeDefinition:
	inputs.append(port_name)
	return self

func add_output(port_name: String) -> CustomNodeDefinition:
	outputs.append(port_name)
	return self

func add_parameter(parameter_name: String, default_value: Variant) -> CustomNodeDefinition:
	parameters[parameter_name] = default_value
	return self

func validate() -> Array[String]:
	var errors: Array[String] = []
	if name.strip_edges().is_empty():
		errors.append("Node name is required")
	if inputs.is_empty() and outputs.is_empty():
		errors.append("Node must define an input or output")
	return errors

func serialize() -> Dictionary:
	return {"name": name, "category": category, "description": description, "inputs": inputs, "outputs": outputs, "parameters": parameters.duplicate(true)}
