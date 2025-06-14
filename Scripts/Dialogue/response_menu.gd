class_name DialogueMenu extends HBoxContainer

## Emitted when a response is selected.
signal response_selected(response)

## button to duplicate
@export var button_template: Control

## The list of dialogue responses.
var responses: Array = []:
	set(value):
		responses = value
		if value:
			make_buttons()

## Holds the buttons
var buttons: Array = []
## Button currently in focus
var focus_idx: int = 0
var is_focus: bool = false

func _ready() -> void:
	if not button_template:
		push_error("I'm missing my template :(")

	if not response_selected.is_connected(_on_selected):
		response_selected.connect(_on_selected)

	visible = false
	visibility_changed.connect(_on_visible_changed)

func make_buttons() -> void:
	buttons = []
	focus_idx = 1
	is_focus = false

	for response in responses:
		var button := button_template.duplicate()
		button.text = response.text
		button.show()
		buttons.append(button)
		add_child(button)
		

func _input(event: InputEvent) -> void:
	if not visible or len(responses) == 0:
		return

	if event.is_action_pressed("select_left"):
		get_viewport().set_input_as_handled()
		response_selected.emit(responses[0])
	elif event.is_action_pressed("select_centre") and len(responses) > 1:
		get_viewport().set_input_as_handled()
		response_selected.emit(responses[1])
	elif event.is_action_pressed("select_right") and len(responses) > 2:
		get_viewport().set_input_as_handled()
		response_selected.emit(responses[2])
	
	
	elif event.is_action_pressed("ui_left"):
		get_viewport().set_input_as_handled()
		buttons[focus_idx].disabled = false
		focus_idx = (focus_idx - 1) % len(responses)
		buttons[focus_idx].disabled = true
		is_focus = true
	elif event.is_action_pressed("ui_right"):
		get_viewport().set_input_as_handled()
		buttons[focus_idx].disabled = false
		focus_idx = (focus_idx + 1) % len(responses)
		buttons[focus_idx].disabled = true
		is_focus = true
	
	elif event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		if is_focus:
			buttons[focus_idx].disabled = false
			buttons[focus_idx].button_pressed = true

	elif is_focus and (event.is_action_released("interact") or event.is_action_released("ui_accept")):
		get_viewport().set_input_as_handled()
		response_selected.emit(responses[focus_idx])
		


func finish() -> void:
	for button in buttons:
		button.queue_free()
	buttons = []
	responses = []
	focus_idx = 1
	is_focus = false
	visible = false

func _on_selected(response) -> void:
	finish()

func _on_visible_changed() -> void:
	if not visible:
		finish()
