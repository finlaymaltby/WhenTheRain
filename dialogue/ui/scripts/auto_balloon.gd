class_name AutoBalloon extends DialogueBalloon

func _start_waiting() -> void:
	waiting_for = EOL_AUTO_ADVANCE
	eol_wait.start(Dialogue.AUTO_WAIT_TIME)
