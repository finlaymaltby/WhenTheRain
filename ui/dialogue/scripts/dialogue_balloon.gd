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

var waiting_for: WaitMode

enum {
	LABEL_TYPING,
	RESPONSE_SELECTING,
	EOL_AUTO_ADVANCE,
	PLAYER_INPUT
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

## Start some dialogue
func start(_dialogue: Dialogue, title: String) -> void:
	dialogue = _dialogue

	if not dialogue.has_label(title):
		push_error("No label exists with the given title: ", title)

	if not dialogue.interrupted.is_connected(_on_dialogue_interrupted):
		dialogue.interrupted.connect(_on_dialogue_interrupted)

	dialogue.start_at(title)
	set_process(true)

func start_next_line():
	dialogue.next()
	waiting_for = LABEL_TYPING
	dialogue_label.start_typing_from(dialouge.curr_turn)

func _process(delta: float) -> void:
	if dialogue.is_finished():
		finish()

func handle_advance() -> void:
	# waiting for the response menu
	if response_menu.visible:
		return

	# waiting for 
	if line_wait.time_left != 0:
		return

	var turn := dialogue.curr_turn

	if turn is DialogueLine.Question:
		response_menu.responses = dialogue.get_responses()
		response_menu.show()
	elif turn.time == 0:
		dialogue.next()
	elif turn.time != -1:
		line_wait.start(turn.time)
	else:
		start_waiting()

## Apply any changes to the balloon given a new [DialogueLine].
func apply_turn() -> void:
	is_waiting = false

	hide()
	var turn := dialogue.curr_turn

	character_label.visible = not turn.speaker.is_empty()
	character_label.text = turn.speaker
	response_menu.hide()
	dialogue_label.turn = turn

	show()

	if not turn.text.is_empty():
		dialogue_label.start_typing()
		await dialogue_label.finished_typing

	if dialogue.is_finished():
		finish()
		return
		

## extra things to do when waiting (e.g. autostart next line)
func start_waiting() -> void:
	is_waiting = true

func next() -> void:
	is_waiting = false
	dialogue.next()
	apply_turn()

## Call to skip the readout
func skip() -> void:
	dialogue_label.skip_typing()

## when there are no lines left in the dialogue dialogue
func finish() -> void:
	set_process(false)
	dialogue.interrupted.disconnect(_on_dialogue_interrupted)

	dialogue = null
	is_waiting = false
	hide()
	response_menu.finish()
	finished.emit()

## Jump the dialogue 
func jump(title: String) -> void:
	if not dialogue.has_label(title):
		push_error("dialogue doesn't have the title you wanna jump to: ", title)
	
	is_waiting = false
	response_menu.responses = []
	dialogue_label.skip_typing()
	line_wait.timeout.emit()

## Only makes the jump if the current dialogue is the one you're trying to jump in
func jump_checked(title: String, _dialogue: Dialogue) -> void:
	if dialogue != _dialogue:
		return 
	jump(title)

func leave() -> void:
	if dialogue.has_label("on_leave"):
		jump("on_leave")
	else:
		dialogue.jump_end()
		next()

func _on_label_finished_typing():
	if not waiting_for == LABEL_TYPING:
		return
	
	

func _on_responses_menu_response_selected(response: DialogueLine.Response) -> void:
	dialogue.pick_response(response)
	next()

func _on_dialogue_interrupted() -> void:
	skip()
	apply_turn()

func _on_eol_wait_timeout() -> void:
	dialogue.next()