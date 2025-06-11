class_name LocalStory extends Node


func _ready() -> void:
	pass

func begin_dialogue(dialogue: DialogueResource, start: String = "start") -> void:
	DialogueManager.show_dialogue_balloon(dialogue, start)
	#balloon.start(dialogue, start, [self])
	#DialogueManager.dialogue_started.emit()
