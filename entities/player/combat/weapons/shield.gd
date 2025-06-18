extends Weapon

func _ready() -> void:
	super()

func _cancel() -> void:
	animation_player.play("shield")
	animation_player.advance(0)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("defend"):
		if manager.request_focus(self):
			animation_player.play("shield")
	
	if event.is_action_released("defend"):
		if manager.has_focus(self):

			animation_player.play_backwards("shield")
			await animation_player.animation_finished
			if manager.has_focus(self):
				finish()
