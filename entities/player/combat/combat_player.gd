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
	
	if $AnimationPlayer.current_animation in ["swing", "shield"]:
		move_and_slide()
		return
		
	if $Shield.is_active:
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
	
func _input(event: InputEvent) -> void:
	if not $Shield.is_active and event.is_action_released("attack"):
		$AnimationPlayer.play("swing")
		
	if event.is_action_pressed("defend"):
		$AnimationPlayer.play("shield")
		$AnimationPlayer.advance(0.2)
	
	if event.is_action_released("defend"):
		$AnimationPlayer.play_backwards("shield")

	$AnimationPlayer.advance(0)
