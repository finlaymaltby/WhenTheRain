class_name DialogueBalloon extends Control
## Base class for all dialogue balloons

signal finished

## The dialogue resource
var dialogue: Dialogue

## IS waiting for the player/input/signal to go to the next line
var is_waiting: bool = false

## timer for dialogue waiting in between lines
var line_wait: Timer = Timer.new()
	
## The label showing the name of the currently speaking character
@onready var character_label: RichTextLabel = %CharacterLabel

## The label showing the currently spoken dialogue
@onready var dialogue_label: DialogueLabel = %DialogueLabel

## The menu of responses
@onready var response_menu: DialogueMenu = %ResponseMenu

func _ready() -> void:
	hide()
	add_child(line_wait)

	if not response_menu.response_selected.is_connected(_on_responses_menu_response_selected):
		response_menu.response_selected.connect(_on_responses_menu_response_selected)

## Start some dialogue
func start(_dialogue: Dialogue, title: String) -> void:
	dialogue = _dialogue
	is_waiting = false
	if not dialogue.has_label(title):
		push_error("No label exists with the given title: ", title)
	if not dialogue.interrupted.is_connected(_on_dialogue_interrupted):
		dialogue.interrupted.connect(_on_dialogue_interrupted)

	dialogue.start_at(title)
	next()

## Apply any changes to the balloon given a new [DialogueLine].
func apply_turn() -> void:
	is_waiting = false
	if dialogue.is_finished():
		finish()
		return
		
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
		
	if turn is DialogueLine.Question:
		response_menu.responses = dialogue.get_responses()
		response_menu.show()
	elif turn.time == 0:
		dialogue.next()
	elif turn.time != -1:
		line_wait.start(turn.time)
		await line_wait.timeout
		dialogue.next()
	else:
		start_waiting()

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

func _on_responses_menu_response_selected(response: DialogueLine.Response) -> void:
	dialogue.pick_response(response)
	next()

func _on_dialogue_interrupted() -> void:
	skip()
	apply_turn()
