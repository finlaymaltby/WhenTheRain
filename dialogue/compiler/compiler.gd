class_name DialogueCompiler extends Node

const SCRIPT_ALIASES: Dictionary[String, String]= {
	"stdlib": "DialogueStdLib",
	"StdLib": "DialogueStdLib"
}

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
	_add_globals()
	_add_required_objects()
	if res._using_object:
		_add_using_object()
	_verify_interrupt_signals()
	return dialogue if was_successful else null

func _add_globals():
	var tree := Engine.get_main_loop() as SceneTree
	var root := tree.root
	for global in res._global_imports:
		var global_name := res._global_imports[global]
		for child in root.get_children():
			if is_instance_of(child, global):
				dialogue.object_bindings[global_name] = child

		if not dialogue.object_bindings.has(global_name):
			throw_error("Could not find autoload '" + global_name + "' in the scene tree")

func _add_required_objects():
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
			throw_error("Could not find '" + script_name + "' of type " + str(script) + " in inputs")

func _add_using_object():
	for unnamed in _unnamed_inputs:
		if is_instance_of(unnamed, res._using_object):
			if dialogue.object_bindings.has("") and dialogue.object_bindings.get("", unnamed) == unnamed:
				throw_error("Ambigious input for '" + str(res._using_object) + "'")
			dialogue.object_bindings[""] = unnamed

	if not dialogue.using_object:
		throw_error("Could not find using required object '" + str(res._using_object) + "'")

func try_access(obj_name: String, property_path: String, can_be_null := false) -> Variant:
	var obj: Object = dialogue.object_bindings.get(obj_name)
	if not obj:
		throw_error("Could not find object '" + obj_name + "' to access '" + property_path + "'")
		return null

	var val = obj.get_indexed(property_path)
	if not (val or can_be_null):
		throw_error("Accessing value '" + property_path + "' from '" + obj_name +  "' returned null")
	return val

func _verify_interrupt_signals() -> void:
	for line in dialogue.res.lines:
		for interrupt in line.interrupts:
			if interrupt.signal_name in dialogue.signal_bindings:
				continue
			var sig = try_access(interrupt.obj_name, interrupt.signal_path)
			if not sig is Signal:
				throw_error("Interrupt signal '" + interrupt.signal_name + "' is not a Signal")
			 
			dialogue.signal_bindings[interrupt.signal_name] = sig as Signal
			_set_signal_arg_count(interrupt)

func _set_signal_arg_count(interrupt: DialogueLine.Interrupt) -> void:
	var root_obj = dialogue.object_bindings[interrupt.obj_name]
	var path := interrupt.signal_path
	var signal_parent: Object
	if interrupt.signal_path.get_subname_count() == 0:
		signal_parent = root_obj
	else:
		var signal_parent_path := path.slice(0, -1).get_as_property_path()
		signal_parent = root_obj.get_indexed(signal_parent_path)

	var signal_arg_count := -1
	for signal_data in signal_parent.get_signal_list():
		
		if interrupt.signal_name.ends_with(signal_data["name"]):
			signal_arg_count = signal_data["args"].size()
	
	if signal_arg_count == -1:
		breakpoint
		push_error("Could not find signal")
		return 

	dialogue._signal_arg_counts[interrupt.signal_name] = signal_arg_count
