class_name CombatCharacter
extends CombatBody

@export var enemy: CombatBody
@export var brain: CombatBrain

var state: PEvent.State 

func _ready() -> void:
	super._ready()
	
	if not enemy:
		push_error("enemy msut be dfined")
	state = PEvent.State.from(self, enemy)

func get_move_dir() -> Vector2:
	return Vector2.ZERO

func _process(delta: float) -> void:
	brain.update_and_run(state)

func _physics_process(delta: float) -> void:
	var move_type := process_movement(delta)
	move_and_slide()

func _on_turned(move_dir: Vector2) -> void:
	if facing_right != (move_dir.x > 0):
		scale.x = -1
		facing_right = move_dir.x > 0
	

func _on_health_component_health_died(dmg_taken: float) -> void:
	queue_free()
