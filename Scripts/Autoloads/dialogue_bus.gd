extends Node

## Is there dialogue already being run
@onready var is_dialogueing: bool = false
@onready var curr_resource: DialogueResource = null

func _ready() -> void:
	DialogueManager.dialogue_started.connect(_on_dialogue_start)
	DialogueManager.dialogue_ended.connect(_on_dialogue_end)

func _on_dialogue_start(res: DialogueResource) -> void:
	is_dialogueing = true
	curr_resource = res

func _on_dialogue_end(res) -> void:
	is_dialogueing = false
	curr_resource = null
