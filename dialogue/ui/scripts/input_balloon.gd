class_name InputBalloon extends DialogueBalloon
## A dialogue balloon that uses player input to advance

func _start_waiting() -> void:
	waiting_for = PLAYER_INPUT

func _input(event: InputEvent) -> void:
	if not visible or waiting_for == RESPONSE_SELECTED: 
		return

	if event.is_action_released("interact"):
		get_viewport().set_input_as_handled()

	if event.is_action_released("cancel") and dialogue_label.is_typing:
		get_viewport().set_input_as_handled()
		skip_typing()

	if waiting_for in [PLAYER_INPUT, EOL_AUTO_ADVANCE]:
		if event.is_action_released("interact"):
			_start_next_line()
	 

	
