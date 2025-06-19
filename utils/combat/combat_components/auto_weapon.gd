class_name AutoWeapon extends Weapon
## weapon with a func run, that automatically plays the given animation.
## Cannot be cancellable

@export var anim_name: StringName

func _ready() -> void:
	super()
	if not anim_name:
		push_error("no animation name found")
	
func _cancel() -> void:
	push_error("auto weapon cannot be cancelled (currently)")

## run the animatino.
func run() -> void:
	if manager.request_focus(self):
		run_anim(anim_name)
	
