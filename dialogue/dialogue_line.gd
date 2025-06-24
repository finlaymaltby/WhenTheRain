class_name DLine extends RefCounted

class Data extends RefCounted:
	## The id of the heading that the line is under
	var heading: int
	var signals: Dictionary[String, int]

	func _init(_heading: int, _signals: Dictionary[String, int]) -> void:
		heading = _heading
		signals = _signals.duplicate()

	func _to_string() -> String:
		return "/" + str(heading) + "/" + str(signals)

var id: int
var data: Data

func _init(_id: int, _data: Data) -> void:
	id = _id
	data = _data

func _to_string() -> String:
	return str(id) + ": " + str(data)

class DLabel extends DLine:
	var name: String
	func _init(_id: int, _name: String, _data: Data) -> void:
		id = _id
		name = _name
		data = _data

	func _to_string() -> String:
		return str(id) + ": " + name + " " + str(data)

class Turn extends DLine:
	var speaker: String
	var turn: String

	func _init(_id: int, _speaker: String, _turn: String, _data: Data) -> void:
		id = _id
		speaker = _speaker
		turn = _turn
		data = _data

	func _to_string() -> String:
		return str(id) + ": " + "'" + speaker + "' says '" + turn + "' " + str(data)

class Question extends Turn:
	var responses: Array[int]

	func _init(_id: int, _speaker: String, _turn: String, _responses: Array[int],  _data: Data) -> void:
		id = _id
		speaker = _speaker
		turn = _turn
		responses = _responses
		data = _data

	func _to_string() -> String:
		return str(id) + ": '" + speaker + "' asks '" + turn + "' " + str(responses) + " " + str(data)

class Response extends DLine:
	var response: String
	func _init(_id: int, _response: String, _data: Data) -> void:
		id = _id
		response = _response
		data = _data

	func _to_string() -> String:
		return str(id) + ": response '" + response + "' " + str(data)

class Mutation extends DLine:
	pass

class Jump extends DLine:
	var jump_id: int
	func _init(_id: int, _jump_id: int, _data: Data) -> void:
		id = _id
		jump_id = _jump_id
		data = _data

	func _to_string() -> String:
		return str(id) + ": ( => " + str(jump_id) + ") " + str(data)

class JumpRet extends Jump:
	func _to_string() -> String:
		return str(id) + ": ( =>< " + str(jump_id) + ") " + str(data)