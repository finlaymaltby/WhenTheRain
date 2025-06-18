class_name OneWeaponManager extends WeaponManager
## A subclass of weapon manager that allows only one weapon to have focus at a time

## The weapon currently in focus
var current_focus: Weapon = null


func request_focus(weapon: Weapon) -> bool:
    if disabled:
        return false  
    elif not current_focus:
        current_focus = weapon
        return true
    elif current_focus.cancelable:
        current_focus.cancel()
        current_focus = weapon
        return true
    return false

func release_focus(weapon: Weapon) -> void:
    if weapon != current_focus:
        push_error("weapon tried to release focus when it didn't have it. (double free)")
    current_focus = null