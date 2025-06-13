class_name LocalStory extends Node

@export var default_balloon: DialogueBalloon

func _ready() -> void:
	if not default_balloon:
		push_error("no dialogue balloon given :(")
	pass

func begin_dialogue(dialogue: DialogueResource, start: String = "start", balloon: DialogueBalloon = default_balloon) -> void:
	balloon.start(dialogue, start, [self])
