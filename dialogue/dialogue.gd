class_name Dialogue extends Node

var script_map: Dictionary[String, Node]

var _unnamed_inputs: Array[Node]
var _named_inputs: Dictionary[String, Node]

var res: DResource

func _init(resource: DResource) -> void:
	res = resource
	script_map = {}

static func create_from_path(path: String) -> Dialogue:
	var file := FileAccess.open("res://dialogue/example.txt", FileAccess.READ)
	var content := file.get_as_text(true)

	var lexer := Lexer.new(content)
	lexer.tokenise()
	var parser := Parser.new(lexer.tokens)
	parser.parse()
	var dialogue := Dialogue.new(parser.resource)
	return dialogue

func add_input(obj: Object):
	_unnamed_inputs.append(obj)

func add_named_input(_name: String, obj: Object) -> void:
	_named_inputs[_name] = obj

func throw_error(msg: String) -> void:
	push_error("Compiler error: " + msg)

func compile() -> void:
	_compile()

func _compile() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var root := tree.root

	for global in res._global_imports:
		var global_name := res._global_imports[global]
		for child in root.get_children():
			if is_instance_of(child, global):
				script_map[global_name] = child

		if not script_map.has(global_name):
			throw_error("Could not find autoload '" + global_name + "' in the scene tree")

	for script in res._required_scripts:
		var script_name := res._required_scripts[script]
		if _named_inputs.has(script_name):
			if not is_instance_of(_named_inputs.get(script_name), script):
				throw_error("Require '" + script_name + "' to be a valid instance of " + script.resource_path)
				return
			else:
				script_map[script_name] = _named_inputs.get(script_name)
				continue
		
		for obj in _unnamed_inputs:
			if is_instance_of(obj, script):
				script_map[script_name] = obj
				continue

		print(type_exists("CombatDemoAngryGuy"))
		print(is_instance_of(_unnamed_inputs[0], script))
		breakpoint
		throw_error("Could not find '" + script.get_global_name() + "' of type " + script.resource_path + " in inputs")
