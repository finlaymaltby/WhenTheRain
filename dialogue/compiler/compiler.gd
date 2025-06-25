class_name DialogueCompiler extends Node

var res: DialogueResource
var dialogue: Dialogue
var was_successful: bool 

var _unnamed_inputs: Array[Object]
var _named_inputs: Dictionary[String, Object]

func _init(_resource: DialogueResource) -> void:
	res = _resource
	dialogue = Dialogue.new(res, {})
	was_successful = true

static func from_path(path: String) -> DialogueCompiler:
	var file := FileAccess.open(path, FileAccess.READ)
	var content := file.get_as_text(true)

	var lexer := DLexer.new(content)
	lexer.tokenise()
	if not lexer.was_successful:
		return null
	var parser := DParser.new(lexer.tokens)
	parser.parse()
	if not parser.was_successful:
		return null
	return DialogueCompiler.new(parser.resource)

func add_using(obj: Object):
	if not obj:
		throw_error("Add input null object")
	_unnamed_inputs.append(obj)

func add_named_input(_name: String, obj: Object) -> void:
	if not obj:
		throw_error("Add input null object")
	_named_inputs[_name] = obj

func throw_error(msg: String) -> void:
	push_error("DialogueCompiler error: " + msg)
	was_successful = false

func compile() -> Dialogue:
	var tree := Engine.get_main_loop() as SceneTree
	var root := tree.root

	for global in res._global_imports:
		var global_name := res._global_imports[global]
		for child in root.get_children():
			if is_instance_of(child, global):
				dialogue.object_bindings[global_name] = child

		if not dialogue.object_bindings.has(global_name):
			throw_error("Could not find autoload '" + global_name + "' in the scene tree")

	for script in res._required_objects:
		var script_name := res._required_objects[script]

		if _named_inputs.has(script_name):
			if not is_instance_of(_named_inputs.get(script_name), script):
				throw_error("Require '" + script_name + "' to be a valid instance of " + script.resource_path)
				return
			else:
				dialogue.object_bindings[script_name] = _named_inputs.get(script_name)
				_named_inputs.erase(script_name)
				continue
		
		for unnamed in _unnamed_inputs:
			if is_instance_of(unnamed, script):
				if dialogue.object_bindings.has(script_name) and dialogue.object_bindings.get(script_name) == unnamed:
					throw_error("Ambigious input for '" + script_name)
				dialogue.object_bindings[script_name] = unnamed

		if not dialogue.object_bindings.has(script_name):
			throw_error("Could not find '" + script_name + "' of type " + script.resource_path + " in inputs")

	if res._using_object:
		for unnamed in _unnamed_inputs:
			if is_instance_of(unnamed, res._using_object):
				if dialogue.object_bindings.has("") and dialogue.object_bindings.get("", unnamed) == unnamed:
					throw_error("Ambigious input for '" + str(res._using_object) + "'")
				dialogue.object_bindings[""] = unnamed

		if not dialogue.using_object:
			throw_error("Could not find using required object '" + str(res._using_object) + "'")

	if not was_successful:
		return null
	else:
		return dialogue
