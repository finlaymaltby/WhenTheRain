class_name InputBalloon extends DialogueBalloon
## A dialogue balloon that uses player input to advance

func _input(event: InputEvent) -> void:
	if not visible: return
	if dialogue_line.responses.size() > 0: return
	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()

	if not is_waiting: return 
	
	
	if event.is_action_pressed("interact"):
		go_next()
		
	elif event.is_action_pressed("cancel") and dialogue_label.is_typing:
		get_viewport().set_input_as_handled()
		skip()
