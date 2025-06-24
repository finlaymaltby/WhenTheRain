class_name InputBalloon extends DialogueBalloon
## A dialogue balloon that uses player input to advance

func _input(event: InputEvent) -> void:
	if not visible: return
	if response_menu.visible: return

	if event.is_action_released("interact"):
		get_viewport().set_input_as_handled()

	if event.is_action_released("cancel") and dialogue_label.is_typing:
		get_viewport().set_input_as_handled()
		skip()

	if not is_waiting: return 

	if event.is_action_released("interact"):
		next()
	