class_name DialogueLabel extends RichTextLabel

signal finished_typing

var turn: DialogueLine.Turn:
	set(val):
		turn = val
		text = ""
		is_finished_typing = false

var delay: float = 0.01
var is_typing := false
var is_finished_typing := false

var _waiting_seconds: float = 0

func start_typing() -> void:
	text = ""
	is_typing = true

func start_typing_from(_turn: DialogueLine.Turn) -> void:
	turn =_turn
	start_typing()

func _process(delta: float) -> void:
	if not is_typing:
		return
	if _waiting_seconds > 0:
		_waiting_seconds -= delta
		return
	_waiting_seconds = delay
	_type_next()

func _type_next() -> void:
	if len(text) == len(turn.text):
		finish()
		return
	text += turn.text[len(text)]


func skip_typing() -> void:
	text = turn.text
	
func finish() -> void:
	is_typing = false
	is_finished_typing = true
	finished_typing.emit()
