class_name Dialogue extends Node

var script_map: Dictionary[String, Node]

var res: DResource

func _init(resource: DResource, _script_map: Dictionary[String, Node]) -> void:
	res = resource
	script_map = _script_map

static func compile_from_path(path: String, _unnamed_inputs: Array[Node], _named_inputs: Dictionary[String, Node]) -> Dialogue:
	var compiler := Compiler.from_path(path)
	for obj in _unnamed_inputs:
		compiler.add_input(obj)

	for key in _named_inputs:
		compiler.add_named_input(key, _named_inputs[key])

	compiler.compile()
	return compiler.dialgoue
