class_name Weapon extends Node2D

## weapon to request focus from
@export var manager: WeaponManager

@export var animation_player: AnimationPlayer
## Can the weapon animation be cancelled at the current moment
@export var cancellable: bool

## disable override
@export var disabled: bool = false


func _ready() -> void:
	if not manager:
		if get_parent() is WeaponManager:
			manager = get_parent()
		else:
			push_error("no weapon manager found :(")


## call to cancel the weapon animation
## overrride the _cancel function in sublcass
func cancel() -> void:
	if not cancellable:
		push_error("tried to cancel an uncancellable moment")

	_cancel()
	finish()

func _cancel() -> void:
	push_error("override in subclass")

## release focus from the manager
func finish() -> void:
	manager.release_focus(self)

## plays the animation, freeing focus when finished
func run_anim(anim: StringName) -> void:
	animation_player.play(anim)
	await animation_player.animation_finished
	if manager.has_focus(self):
		finish()

	
