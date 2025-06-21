extends CombatCharacter

func _ready() -> void:
	super()
	if not balloon:
		push_error("my balloon :(")
	if not dialogue: 
		push_error("my dialouge :(")

func _physics_process(delta: float) -> void:
	var move_type := process_movement(delta)
	move_and_slide()
	
func _on_health_component_health_died(dmg_taken: float) -> void:
	queue_free()
