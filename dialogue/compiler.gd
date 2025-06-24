class_name Compiler extends Node

var res: DResource
var dialogue: Dialogue
var was_successful: bool 

var _unnamed_inputs: Array[Node]
var _named_inputs: Dictionary[String, Node]

func _init(_resource: DResource) -> void:
	res = _resource
	dialogue = Dialogue.new(res, {})
	was_successful = true

static func from_path(path: String) -> Compiler:
	var file := FileAccess.open("res://dialogue/info.txt", FileAccess.READ)
	var content := file.get_as_text(true)

	var lexer := Lexer.new(content)
	lexer.tokenise()
	if not lexer.was_successful:
		return null
	var parser := Parser.new(lexer.tokens)
	parser.parse()
	if not parser.was_successful:
		return null
	return Compiler.new(parser.resource)

func add_input(obj: Object):
	if not obj:
		throw_error("Add input null object")
	_unnamed_inputs.append(obj)

func add_named_input(_name: String, obj: Object) -> void:
	if not obj:
		throw_error("Add input null object")
	_named_inputs[_name] = obj

func throw_error(msg: String) -> void:
	push_error("Compiler error: " + msg)
	was_successful = false

func compile() -> Dialogue:
	var tree := Engine.get_main_loop() as SceneTree
	var root := tree.root

	for global in res._global_imports:
		var global_name := res._global_imports[global]
		for child in root.get_children():
			if is_instance_of(child, global):
				dialogue.script_map[global_name] = child

		if not dialogue.script_map.has(global_name):
			throw_error("Could not find autoload '" + global_name + "' in the scene tree")

	for script in res._required_scripts:
		var script_name := res._required_scripts[script]

		if _named_inputs.has(script_name):
			if not is_instance_of(_named_inputs.get(script_name), script):
				throw_error("Require '" + script_name + "' to be a valid instance of " + script.resource_path)
				return
			else:
				dialogue.script_map[script_name] = _named_inputs.get(script_name)
				continue
		
		for obj in _unnamed_inputs:
			if is_instance_of(obj, script):
				if dialogue.script_map.has(script_name) and dialogue.script_map.get(script_name) != obj:
					throw_error("Ambigious inputs given, for script name '" + script_name + "'")
				dialogue.script_map[script_name] = obj
				break

		if not dialogue.script_map.has(script_name):
			throw_error("Could not find '" + script.get_global_name() + "' of type " + script.resource_path + " in inputs")

	if not was_successful:
		return null
	else:
		return dialogue
