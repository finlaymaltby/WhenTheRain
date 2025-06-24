class_name LocalStory extends Node

@export var default_balloon: DialogueBalloon

func _ready() -> void:
	if not default_balloon:
		push_error("no dialogue balloon given :(")
	pass
	
func begin_dialogue(dialogue: Dialogue, start: String = "START", balloon: DialogueBalloon = default_balloon) -> void:
	balloon.start(dialogue, start)

func leave_dialogue(dialogue: Dialogue, balloon: DialogueBalloon = default_balloon) -> void:
	if balloon.dialogue != dialogue:
		push_warning("trying to leave dialogue you didn't start")
		
	balloon.leave()
