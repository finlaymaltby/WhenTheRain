extends Weapon

func _ready() -> void:
	super()

func _cancel() -> void:
	push_error("override in subclass")


func _unhandled_input(event: InputEvent) -> void:
	breakpoint
