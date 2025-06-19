class_name CombatAngryGuy extends CombatCharacter

const DIST_V_CLOSE := 300
const DIST_CLOSE := 480


## angy guy expecting you to attack?
@onready var is_prepped := false

func _ready() -> void:
	super()

func _process(delta: float) -> void:
	pass

	
func _physics_process(delta: float) -> void:
	var move_type := process_movement(delta)
	if $OneWeaponManager.current_focus:
		move_and_slide()
		return
	
	match move_type:
		MoveType.STILL:
			$AnimationPlayer.play("idle")
		MoveType.WALKING:
			$AnimationPlayer.play("run")
		MoveType.SLIDING:
			$AnimationPlayer.play("idle")
		MoveType.FALLING:
			$AnimationPlayer.play("jump")

	move_and_slide()
	
func _on_health_component_health_died(dmg_taken: float) -> void:
	queue_free()
