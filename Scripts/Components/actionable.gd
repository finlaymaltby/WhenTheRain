class_name Actionable extends Area2D

@export var dialogue: DialogueResource
@export var dialogue_start: String = "start"

var scene: LocalStory

func _ready() -> void:
	if not dialogue:
		push_error("missing dialogue resource")
		
	if get_tree().current_scene is LocalStory:
		scene = get_tree().current_scene
	else:
		push_error("scene root isn't a story? :()")
	
	set_collision_layer_value(5, true)
		
func action() -> void:
	scene.begin_dialogue(dialogue, dialogue_start)
