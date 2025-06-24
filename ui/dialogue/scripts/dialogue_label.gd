class_name DialogueLabel extends RichTextLabel

signal finished_typing

var turn: DialogueLine.Turn:
	set(val):
		turn = val
		text = ""

var delay: float = 0.01

var is_typing := false
var _waiting_seconds: float = 0

func _process(delta: float) -> void:
	if not is_typing:
		return
	if _waiting_seconds > 0:
		_waiting_seconds -= delta
		return
	_waiting_seconds = delay
	type_next()

func type_next() -> void:
	if len(text) == len(turn.text):
		finished_typing.emit()
		return
	text += turn.text[len(text)]

func start_typing() -> void:
	text = ""
	is_typing = true

func skip_typing() -> void:
	is_typing = false
	text = turn.text
	finished_typing.emit()
