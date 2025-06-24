class_name DialogueLine extends RefCounted

class Data extends RefCounted:
	## The id of the heading that the line is under
	var heading: int
	var interrupts: Dictionary[String, int]

	func _init(_heading: int, _interrupts: Dictionary[String, int]) -> void:
		heading = _heading
		interrupts = _interrupts.duplicate()

	func _to_string() -> String:
		return "/" + str(heading) + "/" + str(interrupts)

var id: int
var next_id: int
var data: Data

func _init(_id: int, _data: Data) -> void:
	id = _id
	next_id = id+1
	data = _data

func _to_string() -> String:
	return str(id) + ": " + str(data)

class DLabel extends DialogueLine:
	var name: String
	func _init(_id: int, _name: String, _data: Data) -> void:
		id = _id
		next_id = id+1
		name = _name
		data = _data

	func _to_string() -> String:
		return str(id) + ": " + name + " " + str(data)

class Turn extends DialogueLine:
	var speaker: String
	var text: String
	var time: int = -1

	func _init(_id: int, _speaker: String, _text: String, _data: Data) -> void:
		id = _id
		next_id = id+1
		speaker = _speaker
		text = _text
		data = _data

	func _to_string() -> String:
		return str(id) + ": " + "'" + speaker + "' says '" + text + "' " + str(data)

class Question extends Turn:
	var responses: Array[int]

	func _init(_id: int, _speaker: String, _text: String, _responses: Array[int],  _data: Data) -> void:
		id = _id
		next_id = id+1
		speaker = _speaker
		text = _text
		responses = _responses
		data = _data

	func _to_string() -> String:
		return str(id) + ": '" + speaker + "' asks '" + text + "' " + str(responses) + " " + str(data)

class Response extends DialogueLine:
	var text: String
	func _init(_id: int, _text: String, _data: Data) -> void:
		id = _id
		next_id = id+1
		text = _text
		data = _data

	func _to_string() -> String:
		return str(id) + ": response '" + text + "' " + str(data)

class Mutation extends DialogueLine:
	func run_mutation(dialogue: Dialogue) -> void:
		push_error("Override in subclass")

class Set extends Mutation:
	var obj_name: String
	var property: String
	var value: Expression

	func _init(_id: int, _obj_name: String, _property: String, _value: Expression, _data: Data) -> void:
		id = _id
		next_id = id+1
		data = _data
		obj_name = _obj_name
		property = _property
		value = _value

	func run_mutation(dialogue: Dialogue) -> void:
		var obj: Object = dialogue._script_map.get(obj_name, null)
		if obj:
			var result = value.execute([], dialogue._script_map.get("", null))
			if value.has_execute_failed():
				push_error("value execution failed on: ", str(self))
			else:
				obj.set(property, result)

	func _to_string() -> String:
		return str(id) + ": SET " + obj_name + ".get(" + property + ") " + " = " + str(value) + str(data)

class Jump extends DialogueLine:
	func _init(_id: int, _jump_id: int, _data: Data) -> void:
		id = _id
		
		next_id = _jump_id
		data = _data

	func _to_string() -> String:
		return str(id) + ": ( => " + str(next_id) + ") " + str(data)

class JumpRet extends Jump:
	func _to_string() -> String:
		return str(id) + ": ( =>< " + str(next_id) + ") " + str(data)
