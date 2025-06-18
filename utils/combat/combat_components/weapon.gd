class_name Weapon extends Node

## weapon to request focus from
@export var manager: WeaponManager

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

func _cancel() -> void:
	push_error("override in subclass")