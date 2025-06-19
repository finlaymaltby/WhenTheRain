extends CombatBody
class_name CombatPlayer

func _ready() -> void:
	super._ready()
	
func get_move_dir() -> Vector2:
	var move_dir := Vector2.ZERO
	move_dir.x = Input.get_axis("move_left", "move_right")
	
	if Input.is_action_just_pressed("move_up"):
		move_dir.y = -1
	
	return move_dir

func _physics_process(delta: float) -> void:
	var move_type := process_movement(delta)
	
	if $OneWeaponManager.current_focus:
		move_and_slide()
		return 

	match move_type:
		MoveType.STILL:
			$AnimationPlayer.play("idle")
		MoveType.WALKING:
			$AnimationPlayer.play("walk")
		MoveType.SLIDING:
			$AnimationPlayer.play("idle")
		MoveType.FALLING:
			$AnimationPlayer.play("idle")

	move_and_slide()
	
