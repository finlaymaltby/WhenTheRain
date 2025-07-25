class_name Interactable extends Area2D

@export_file("*.txt") var dialogue_path: String
var dialogue: Dialogue
@export var dialogue_start: String = "START"
@export var balloon: DialogueBalloon

var scene: LocalStory
var interacter: CollisionObject2D = null

func _ready() -> void:
	if not dialogue_path:
		push_error("missing dialogue path")
	
	if get_tree().current_scene is LocalStory:
		scene = get_tree().current_scene
	else:
		push_error("scene root isn't a story? :(")
	
	dialogue = Dialogue.compile_from_raw(dialogue_path, [scene], {})
	
	set_collision_layer_value(5, true)
	set_collision_mask_value(6, true)
	interacter = null
	
	if not body_exited.is_connected(_on_exited):
		body_exited.connect(_on_exited)
		
	if not area_exited.is_connected(_on_exited):
		area_exited.connect(_on_exited)
	
func interact(_interacter: CollisionObject2D) -> void:
	scene.begin_dialogue(dialogue, dialogue_start)
	interacter = _interacter
	

func _on_exited(node: Node2D):
	if not balloon:
		return
	if balloon.dialogue == dialogue:
		scene.leave_dialogue(dialogue)
	interacter = null
