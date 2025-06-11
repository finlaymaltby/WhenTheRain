extends CharacterBody2D

const SPEED := 400.0

var is_alive: bool = true

enum Direction {
	UP,
	DOWN,
	LEFT,
	RIGHT
}

var face_dir: Direction

func _process(delta: float) -> void:
	$ActionableFinder.rotation = dir_to_rot(face_dir)
	
func _physics_process(delta: float) -> void:
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if dir.dot(dir_to_vec(face_dir)) <= 0 and dir.length() > 0:
		face_dir = vec_to_dir(dir)
	
	dir = dir.normalized()
	velocity = dir * SPEED
		
	if velocity.length() == 0:
		$AnimationPlayer.play("idle")
	else:
		$AnimationPlayer.play("walk")
	
	if dir.x > 0:
		$Sprite.flip_h = false
	elif dir.x < 0:
		$Sprite.flip_h = true

	move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("attack"):
		var actionables = $ActionableFinder.get_overlapping_areas()
		if actionables.size() == 0:
			return
		var actionable := actionables[0] as Actionable
		actionable.action()

# assumes right is 0, in radians
func dir_to_rot(direction: Direction) -> float:
	var rot: float
	match direction:
		Direction.UP:
			rot = 3*PI/2
		Direction.DOWN:
			rot = PI/2
		Direction.LEFT:
			rot = PI
		Direction.RIGHT:
			rot = 0
	return rot
	
func dir_to_vec(direction: Direction) -> Vector2:
	var vec: Vector2
	match direction:
		Direction.UP:
			vec = Vector2(0,-1)
		Direction.DOWN:
			vec = Vector2(0,1)
		Direction.LEFT:
			vec = Vector2(-1,0)
		Direction.RIGHT:
			vec = Vector2(1,0)
	return vec
	
func vec_to_dir(dir: Vector2) -> Direction:
	if dir.x == 1:
		return Direction.RIGHT
	elif dir.x == -1:
		return Direction.LEFT
	elif dir.y == -1:
		return Direction.UP
	else:
		return Direction.DOWN
		
func _on_health_component_health_died(dmg_taken: float) -> void:
	is_alive = false
	$AnimationPlayer.play("dead")
