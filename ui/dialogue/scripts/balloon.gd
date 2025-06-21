class_name DialogueBalloon extends Control
## Base class for all dialogue balloons

signal finished

const AUTO_WAIT_TIME: float = 1

## The dialogue resource
var dialogue: DialogueResource

## Temporary game states
var temporary_game_states: Array = []

## See if we are waiting for the player/input/signal to go
var is_waiting: bool = false

## A dictionary to store any ephemeral variables
var locals: Dictionary = {}

## Used in 'next' functions when an override is waiting
var line_override: String

## The current line
var dialogue_line: DialogueLine:
	set(value):
		if value:
			dialogue_line = value
			apply_dialogue_line()
		else:
			finish()

## A cooldown timer for delaying the balloon hide when encountering a mutation.
var mutation_cooldown: Timer = Timer.new()

## timer for dialogue waiting in between lines
var line_wait: Timer = Timer.new()

## idk :(
var curr_title: String = ""
	
## The label showing the name of the currently speaking character
@onready var character_label: RichTextLabel = %CharacterLabel

## The label showing the currently spoken dialogue
@onready var dialogue_label: DialogueLabel = %DialogueLabel

## The menu of responses
@onready var response_menu: DialogueMenu = %ResponseMenu


func _ready() -> void:
	hide()
	DialogueManager.mutated.connect(_on_mutated)
	
	mutation_cooldown.timeout.connect(_on_mutation_cooldown_timeout)
	add_child(mutation_cooldown)
	add_child(line_wait)

	if not response_menu.response_selected.is_connected(_on_responses_menu_response_selected):
		response_menu.response_selected.connect(_on_responses_menu_response_selected)

## Start some dialogue
func start(dialogue_resource: DialogueResource, title: String, extra_game_states: Array = []) -> void:
	dialogue = dialogue_resource
	is_waiting = false
	temporary_game_states = [self] + extra_game_states
	self.dialogue_line = await dialogue.get_next_dialogue_line(title, temporary_game_states)

## Apply any changes to the balloon given a new [DialogueLine].
func apply_dialogue_line() -> void:
	mutation_cooldown.stop()
	is_waiting = false
	character_label.visible = not dialogue_line.character.is_empty()
	character_label.text = dialogue_line.character

	dialogue_label.hide()
	dialogue_label.dialogue_line = dialogue_line

	response_menu.hide()
	response_menu.responses = dialogue_line.responses

	show()
	dialogue_label.show()
	if not dialogue_line.text.is_empty():
		dialogue_label.type_out()
		await dialogue_label.finished_typing
	
	if dialogue_line.responses.size() > 0:
		response_menu.show()
	elif dialogue_line.time != "":
		var time := AUTO_WAIT_TIME if dialogue_line.time == "auto" else dialogue_line.time.to_float()
		line_wait.start(time)
		await line_wait.timeout
		next()
	else:
		when_waiting()

## extra things to do when waiting (e.g. autostart next line)
func when_waiting() -> void:
	is_waiting = true


## Advances to the given dialogue line, can be overrided with line_override
func advance_to_next(next_id: String) -> void:
	if line_override:
		next_id = line_override
		line_override = ""
	self.dialogue_line = await dialogue.get_next_dialogue_line(next_id, temporary_game_states)

## Go to the set_next line auto
func next() -> void:
	var next_id := dialogue_line.next_id
	if line_override:
		next_id = line_override
		line_override = ""

	self.dialogue_line = await dialogue.get_next_dialogue_line(next_id, temporary_game_states)

## Call to skip the readout
func skip() -> void:
	dialogue_label.skip_typing()

## when there are no lines left in the dialogue dialogue
func finish() -> void:
	dialogue = null
	temporary_game_states = []
	is_waiting = false
	hide()
	response_menu.finish()

	finished.emit()


## does the dialogue resource have the title (to jump to)
func has_title(title: String) -> bool:
	return title in dialogue.get_titles()

## Jump the dialogue 
func jump(title: String) -> void:
	if not has_title(title) and title != DMConstants.ID_END:
		push_error("dialogue doesn't have the title you wanna jump to: ", title)
	
	line_override = title
	is_waiting = false
	response_menu.responses = []
	dialogue_label.skip_typing()
	line_wait.timeout.emit()

## Only makes the jump if the current dialogue is the one you're trying to jump in
func jump_checked(title: String, _dialogue: DialogueResource) -> void:
	if dialogue != _dialogue:
		return 
	jump(title)

func leave() -> void:
	if has_title("on_leave"):
		jump("on_leave")
	else:
		jump(DMConstants.ID_END)

func _on_mutation_cooldown_timeout() -> void:
	push_error("func not configured yet")
	pass

func _on_mutated(mutation: Dictionary) -> void:
	is_waiting = false

func _on_responses_menu_response_selected(response: DialogueResponse) -> void:
	advance_to_next(response.next_id)
