class_name AutoBalloon extends DialogueBalloon

func when_waiting() -> void:
	var time := AUTO_WAIT_TIME if dialogue_line.time == "auto" else dialogue_line.time.to_float()
	line_wait.start(time)
	await line_wait.timeout
	next()
