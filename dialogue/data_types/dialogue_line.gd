class_name DialogueLine extends RefCounted

const _DISPLAY_BODY_LEN := 50

var id: int
var next_id: int
var interrupts: Array[Interrupt]

func _init(_id: int, _interrupts: Array[Interrupt]) -> void:
	id = _id
	next_id = id + 1
	interrupts = _interrupts

func _to_string() -> String:
	var left :=  "%2d: " % id + __to_string()

	return left.rpad(_DISPLAY_BODY_LEN, " ") + " (=>" + str(next_id) + ") " + str(interrupts)

func __to_string() -> String:
	push_error("override")
	return ""

class Title extends DialogueLine:
	var name: String

	func _init(_id: int, _name: String, _interrupts: Array[Interrupt]) -> void:
		id = _id
		next_id = id + 1
		name = _name
		interrupts = _interrupts.duplicate()

	func __to_string() -> String:
		return "TITLE " + name 

class Turn extends DialogueLine:
	var speaker: String
	var text: String
	var time: int = -1

	func _init(_id: int, _speaker: String, _text: String, _interrupts: Array[Interrupt]) -> void:
		id = _id
		next_id = id + 1
		speaker = _speaker
		text = _text
		interrupts = _interrupts

	func __to_string() -> String:
		return "TURN '" + speaker + "' - '" + text + '"'

class Question extends Turn:
	var responses: Array[int]

	func _init(_id: int, _speaker: String, _text: String, _responses: Array[int],  _interrupts: Array[Interrupt]) -> void:
		id = _id
		next_id = id + 1
		speaker = _speaker
		text = _text
		responses = _responses
		interrupts = _interrupts

	func __to_string() -> String:
		return "QUESTION '" +speaker + "' - '" + text + "' " + str(responses)

class Response extends DialogueLine:
	var text: String
	func _init(_id: int, _text: String, _interrupts: Array[Interrupt]) -> void:
		id = _id
		next_id = id + 1
		text = _text
		interrupts = _interrupts

	func __to_string() -> String:
		return  "RESPONSE '" + text + "'"

class Mutation extends DialogueLine:
	func run_mutation(dialogue: Dialogue) -> void:
		push_error("Override in subclass")

class Set extends Mutation:
	## The (aliased) name of the object in the file scope.
	## e.g. 'pe', 'Gobal', OR "" if a property of the local scope
	var obj_name: String

	## String NodePath of the property
	## e.g. "state:body:position"
	var property: String
	var value: Expression

	func _init(_id: int, _obj_name: String, _property_path: String, _value: Expression, _interrupts: Array[Interrupt]) -> void:
		id = _id
		next_id = id + 1
		interrupts = _interrupts
		obj_name = _obj_name
		property = _property_path
		value = _value

	func run_mutation(dialogue: Dialogue) -> void:
		var obj: Object = dialogue.object_bindings.get(obj_name, null)
		if obj:
			var result = value.execute(dialogue.object_bindings.values(), dialogue.object_bindings.get("", null))
			if value.has_execute_failed():
				push_error("Execution error '" + value.get_error_text() + "' in " + str(self))
			else:
				obj.set_indexed(property, result)

	func __to_string() -> String:
		return "SET " + obj_name + ".(" + property + ") = " + Dialogue._expr_to_string(value)

class Execute extends Mutation:
	var expr: Expression
	func _init(_id: int, _expr: Expression, _interrupts: Array[Interrupt]) -> void:
		id = _id
		next_id = id+1
		expr = _expr
		interrupts = _interrupts
		
	func run_mutation(dialogue: Dialogue) -> void:
		var _result = expr.execute(dialogue.object_bindings.values(), dialogue.object_bindings.get("", null))
		if expr.has_execute_failed():
			push_error("Execution error '" + expr.get_error_text() + "' in " + str(self))

	func __to_string() -> String:
		return "EXEC " + Dialogue._expr_to_string(expr)

				
class Jump extends DialogueLine:
	func _init(_id: int, _jump_id: int, _interrupts: Array[Interrupt]) -> void:
		id = _id
		
		next_id = _jump_id
		interrupts = _interrupts

	func __to_string() -> String:
		return ""

class JumpRet extends Jump:
	func _to_string() -> String:
		return str(id) + ": (=><" + str(next_id) + ")" + str(interrupts)


class Interrupt extends RefCounted:
	var obj_name: String 
	var signal_path: NodePath 
	var signal_name: String

	func run_mutation(dialogue: Dialogue) -> void:
		push_error("override in subclass")

	func _to_string() -> String:
		return "?" + obj_name + ".(" + str(signal_path) + ")" + __to_string()

	func __to_string() -> String:
		push_error("override")
		return ""

class InterruptJump extends Interrupt:
	var jump_id: int
	func _init(_obj_name: String, _signal_path: String, _jump_id) -> void:
		obj_name = _obj_name
		signal_path = _signal_path
		jump_id = _jump_id

		signal_name = obj_name + ":" + str(signal_path)

	func run_mutation(dialogue: Dialogue) -> void:
		dialogue._curr_id = jump_id

	func __to_string() -> String:
		return "=>" + str(jump_id)
