class_name DialogueLine extends RefCounted

const _DISPLAY_BODY_LEN := 50

var id: int
var next_id_override: int = Dialogue.ID_UNDEF
var interrupts: Array[Interrupt]

func next_id() -> int:
	return (id + 1) if next_id_override == Dialogue.ID_UNDEF else next_id_override

func _init(_id: int, _interrupts: Array[Interrupt]) -> void:
	id = _id
	interrupts = _interrupts

func _to_string() -> String:
	var left :=  "%2d: " % id + __to_string()

	return left.rpad(_DISPLAY_BODY_LEN, " ") + " (=>" + str(next_id()) + ") " + str(interrupts)

func __to_string() -> String:
	push_error("override")
	return ""

class Title extends DialogueLine:
	var name: String

	func _init(_id: int, _name: String, _interrupts: Array[Interrupt]) -> void:
		id = _id
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
		speaker = _speaker
		text = _text
		interrupts = _interrupts

	func __to_string() -> String:
		return "TURN '" + speaker + "' - '" + text + '"'

class Question extends Turn:
	var responses: Array[int]

	func _init(_id: int, _speaker: String, _text: String, _responses: Array[int],  _interrupts: Array[Interrupt]) -> void:
		id = _id
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
		
		next_id_override = _jump_id
		interrupts = _interrupts

	func __to_string() -> String:
		return ""

class JumpRet extends Jump:
	func _to_string() -> String:
		return str(id) + ": (=><" + str(next_id_override) + ")" + str(interrupts)

class If extends Mutation:
	var expr: Expression
	var else_id: int

	func _init(_id, _expr: Expression, _else_id: int, _interrupts: Array[Interrupt]) -> void:
		id = _id
		next_id_override = Dialogue.ID_UNDEF
		expr = _expr
		else_id = _else_id
		interrupts = _interrupts

	func run_mutation(dialogue: Dialogue) -> void:
		var result = await expr.execute(dialogue.object_bindings.values(), dialogue.object_bindings.get("", null))
		
		if expr.has_execute_failed():
			push_error("Execution error '" + expr.get_error_text() + "' in " + str(self))
		
		if result:
			next_id_override = id + 1
		else:
			next_id_override = else_id

	func next_id() -> int:
		if next_id_override == Dialogue.ID_UNDEF:
			breakpoint
			push_error("Asking for next line on an if statement that hasn't been mutated")
			return Dialogue.ID_UNDEF

		var ret := next_id_override
		next_id_override = Dialogue.ID_UNDEF
		return ret
	
	func _to_string() -> String:
		return str(id) + "IF " + Dialogue._expr_to_string(expr) + " (else =>" + str(else_id) + ") " + str(interrupts)


class Else extends DialogueLine:
	func _init(_id: int, _interrupts: Array[Interrupt]) -> void:
		id = _id
		next_id_override = id + 1
		interrupts = _interrupts

	func __to_string() -> String:
		return "ELSE"

class Interrupt extends RefCounted:
	var obj_name: String 
	var subpath: NodePath 
	var signal_path: String

	func run_mutation(dialogue: Dialogue) -> void:
		push_error("override in subclass")

	func _to_string() -> String:
		return "?" + obj_name + ".(" + str(subpath) + ")" + __to_string()

	func __to_string() -> String:
		push_error("override")
		return ""

class InterruptJump extends Interrupt:
	var jump_id: int
	func _init(_obj_name: String, _subpath: String, _jump_id) -> void:
		obj_name = _obj_name
		subpath = _subpath
		jump_id = _jump_id

		signal_path = obj_name + ":" + str(subpath)

	func run_mutation(dialogue: Dialogue) -> void:
		dialogue._curr_id = jump_id

	func __to_string() -> String:
		return "=>" + str(jump_id)
