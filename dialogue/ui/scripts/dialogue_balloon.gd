class_name DialogueBalloon extends Control
## Base class for all dialogue balloons

signal finished

## The dialogue resource
var dialogue: Dialogue
	
## The label showing the name of the currently speaking character
@onready var character_label: RichTextLabel = %CharacterLabel

## The label showing the currently spoken dialogue
@onready var dialogue_label: DialogueLabel = %DialogueLabel

## The menu of responses
@onready var response_menu: DialogueMenu = %ResponseMenu

## Timer for waiting for auto-advance at the end of lines
var eol_wait: Timer = Timer.new()

var waiting_for: int

enum {
	LABEL_TYPED,
	RESPONSE_SELECTED,
	EOL_AUTO_ADVANCE,
	PLAYER_INPUT,
	NOT_WAITING,
	FINISHED
}

func _ready() -> void:
	hide()
	set_process(false)

	eol_wait.one_shot = true
	eol_wait.autostart = false
	add_child(eol_wait)
	eol_wait.timeout.connect(_on_eol_wait_timeout)

	if not response_menu.response_selected.is_connected(_on_responses_menu_response_selected):
		response_menu.response_selected.connect(_on_responses_menu_response_selected)

	dialogue_label.finished_typing.connect(_on_label_finished_typing)

func _process(delta: float) -> void:
	if dialogue.is_finished():
		finish()

## Start some dialogue from the given title
func start(_dialogue: Dialogue, title: String) -> void:
	dialogue = _dialogue

	if not dialogue.has_label(title):
		push_error("No label exists with the given title: ", title)

	if not dialogue.interrupted.is_connected(_on_dialogue_interrupted):
		dialogue.interrupted.connect(_on_dialogue_interrupted)

	dialogue.start_at(title)
	set_process(true)
	_start_next_line()

func _start_next_line():
	dialogue.next_turn()
	var turn := dialogue.curr_turn
	show()
	waiting_for = LABEL_TYPED
	character_label.visible = not turn.speaker.is_empty()
	character_label.text = turn.speaker
	response_menu.hide()
	dialogue_label.start_typing_from(turn)

func _handle_advance() -> void:
	var turn := dialogue.curr_turn

	if turn is DialogueLine.Question:
		waiting_for = RESPONSE_SELECTED
		response_menu.responses = dialogue.get_responses()
		response_menu.show()
	elif turn.time == 0:
		_start_next_line()
	elif turn.time > 0:
		waiting_for = EOL_AUTO_ADVANCE
		eol_wait.start(turn.time)
	else:
		_start_waiting()

## What to do when waiting when need an exernal signal to advance to next line.
## e.g. player input, forced auto advance, etc.
func _start_waiting() -> void:
	push_error("override in subclass")

## Call to skip the readout typing
func skip_typing() -> void:
	if waiting_for == LABEL_TYPED:
		dialogue_label.skip_typing()
	else:
		breakpoint

## When the dialogue reaches END
func finish() -> void:
	waiting_for = FINISHED
	set_process(false)
	dialogue.interrupted.disconnect(_on_dialogue_interrupted)
	dialogue = null
	hide()
	response_menu.finish()
	finished.emit()

## Jump the dialogue 
func jump(title: String) -> void:
	if not dialogue.has_label(title):
		push_error("dialogue doesn't have the title you wanna jump to: ", title)
	
	_interrupt_waiters()
	dialogue.start_at(title)
	_start_next_line()

## Only makes the jump if the current dialogue is the one you're trying to jump in
func jump_checked(title: String, _dialogue: Dialogue) -> void:
	if dialogue != _dialogue:
		return 
	jump(title)

func leave() -> void:
	jump("_on_leave" if dialogue.has_label("_on_leave") else "END")

func _on_label_finished_typing():
	if waiting_for == LABEL_TYPED:
		_handle_advance()

func _on_responses_menu_response_selected(response: DialogueLine.Response) -> void:
	if waiting_for == RESPONSE_SELECTED:
		dialogue.pick_response(response)
		_start_next_line()

func _on_eol_wait_timeout() -> void:
	if waiting_for == EOL_AUTO_ADVANCE:
		_start_next_line()

func _interrupt_waiters() -> void:
	waiting_for = NOT_WAITING
	dialogue_label.skip_typing()
	response_menu.finish()
	eol_wait.timeout.emit()

func _on_dialogue_interrupted() -> void:
	_interrupt_waiters()
	_start_next_line()
