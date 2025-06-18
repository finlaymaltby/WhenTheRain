class_name WeaponManager extends Node
## A class to manage weapon focus

## override to prevent any weapon from getting focus
@export var disabled = false


## Ask the manager to have weapon focus.
## Returns true if focus is given
func request_focus(weapon: Weapon) -> bool:
    if disabled:
        return false

    push_error("override in subclass")
    return false


func release_focus(weapon: Weapon) -> void:
    push_error("override in subclass")