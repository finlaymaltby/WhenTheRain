class_name CombatBody
extends CharacterBody2D

signal turned(move_dir: Vector2)
var facing_right = true

@export var health: HealthComponent

## mass used to calulate knockback: J/m = v2 - v1
@export var mass: float 
## speed of character under their control on ground
## :: 100px per sec
@export var speed: float
## deceleration v -= drag * v * delta
## :: per sec
@export var drag: float = 2.0

## vertical impulse when jumping
## :: 100px per sec
@export var jump_speed: float
## speed of character in the air
## :: 100px per sec
@export var air_speed: float
## deceleration v -= drag * v * delta
## :: per sec
@export var air_drag: float = 1.0

## is the player in control of their movement, i.e. been stunned
@export var in_control: bool

enum MoveType {
	STILL,
	WALKING,
	SLIDING,
	FALLING
}

func _ready() -> void:
	if not health:
		push_error("no health comp found")
	if not mass:
		push_error("mass set to 0/undefined, are you sure")
	if not speed:
		push_error("speed set to 0, are you sure")
	if not drag:
		push_error("drag not set")
	if not air_speed:
		push_error("air speed not set")
	if not air_drag:
		push_error("air drag not set")
		
	if not turned.is_connected(_on_turned):
		push_warning("signal not connected")
		turned.connect(_on_turned)

func get_move_dir() -> Vector2:
	push_error("get_move_dir undefined.")
	return Vector2.ZERO
	
## Call do decide the character's velocity
## Returns (movetype, turned_arond
func process_movement(delta: float) -> MoveType:
	var move_dir := get_move_dir()
	var move_type := MoveType.STILL
	
	if not is_on_floor():
		velocity += get_gravity() * delta
		velocity.x -= sign(velocity.x) * min(abs(velocity.x)*air_drag*delta, abs(velocity.x))

		if in_control:
			if abs(velocity.x) <= air_speed*100:
				if sign(velocity.x) != move_dir.x and move_dir.x != 0:
					turned.emit(move_dir)
				velocity.x = move_dir.x * air_speed * 100
				
		move_type = MoveType.FALLING
	else:
		velocity.y = jump_speed * move_dir.y * 100
		
		velocity.x -= sign(velocity.x) * min(abs(velocity.x)*drag*delta, abs(velocity.x))
			
		move_type = MoveType.SLIDING
		if in_control:
			if abs(velocity.x) <= speed*100:
				if sign(velocity.x) != move_dir.x and move_dir.x != 0:
					turned.emit(move_dir)
				velocity.x = move_dir.x * speed * 100
				move_type = MoveType.WALKING
		
	if velocity == Vector2.ZERO:
		move_type = MoveType.STILL
				
	return move_type
	
func knockback(impulse: Vector2) -> void:
	# delta v due to impulse
	var delta_v := (impulse/mass) * 100
	# player velocity in direction of impulse
	var s := velocity.dot(delta_v.normalized())
	# player is going ina opposite direction to knockback
	if s <= 0:
		velocity += delta_v
	elif s < delta_v.length():
		# dont' add more velocity than impulse can supply
		var w := velocity - s * delta_v.normalized()
		velocity = delta_v + w

func _on_turned(move_dir: Vector2) -> void:
	if facing_right != (move_dir.x > 0):
		scale.x = -1
		facing_right = move_dir.x > 0
		
	
