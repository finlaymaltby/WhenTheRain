class_name DialogueMenuQuick extends DialogueMenu
## dialogue menu that only uses quick response shortcuts (not interact)

func _input(event: InputEvent) -> void:
	if not visible or len(responses) == 0:
		return

	if event.is_action_pressed("select_left"):
		if _is_focus and _focus_idx == 0:
			response_selected.emit(responses[0])
		else:
			switch_focus(0)
	elif event.is_action_pressed("select_centre") and len(responses) > 1:
		if _is_focus and _focus_idx == 1:
			response_selected.emit(responses[1])
		else:
			switch_focus(1)
	elif event.is_action_pressed("select_right") and len(responses) > 2:
		if _is_focus and _focus_idx == 2:
			response_selected.emit(responses[2])
		else:
			switch_focus(2)
	elif event.is_action_pressed("ui_left"):
		switch_focus((_focus_idx - 1) % len(responses))
	elif event.is_action_pressed("ui_right"):
		switch_focus((_focus_idx + 1) % len(responses))
	else:
		return
		
	get_viewport().set_input_as_handled()
