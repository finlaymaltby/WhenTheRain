class_name ShieldBox extends HurtBox

## Whether the shield is currently active and 
@export var is_active: bool:
	set(value):
		is_active = value
		set_deferred("monitorable", is_active)
		set_deferred("monitoring", is_active)
		coll_shape.set_deferred("disabled", not is_active)


func _ready() -> void:
	super()
	is_active = false
