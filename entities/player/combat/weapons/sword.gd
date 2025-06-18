extends Weapon

func _ready() -> void:
	super()

func _cancel() -> void:
	$SwordSwing.is_active = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_released("attack"):
		if manager.request_focus(self):
			run_anim("swing")
