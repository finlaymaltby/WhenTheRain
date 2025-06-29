class_name CombatAngryGuy extends CombatCharacter

const DIST_V_CLOSE := 310
const DIST_CLOSE := 600

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
	
func swing() -> void:
	$OneWeaponManager/Sword.run()
	
func laser() -> void:
	$OneWeaponManager/LaserGun.run()

func _on_health_died(dmg_taken: float) -> void:
	balloon.jump_checked("on_death", dialogue)
