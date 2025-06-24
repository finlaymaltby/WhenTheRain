class_name AutoBalloon extends DialogueBalloon

func start_waiting() -> void:
	var turn := dialogue.curr_turn
	line_wait.start(turn.time)
	await line_wait.timeout
	next()
