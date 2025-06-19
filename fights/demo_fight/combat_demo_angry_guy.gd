extends CombatAngryGuy

@export var dialogue: DialogueResource
@export var balloon: DialogueBalloon

func _ready() -> void:
	super()
	if not balloon:
		push_error("my balloon :(")
	if not dialogue: 
		push_error("my dialouge :(")
		
	balloon.start(dialogue, "start", [self])
	
	get_tree().create_timer(2).timeout.connect(swing)

func get_move_dir() -> Vector2:
	return Vector2.RIGHT
