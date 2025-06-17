class_name ShieldBox extends Area2D

@export var stats: StatBlock
@export var is_active: bool = false:
	set(value):
		is_active = value
		coll_shape.disabled = not is_active
@export var block_mode: bool = false

var coll_shape: CollisionShape2D

func _ready() -> void:
	if not stats:
		push_error("no stats found")
		
	if not area_entered.is_connected(_on_area_entered):
		push_warning("area entered not connected, doing with code")
		area_entered.connect(_on_area_entered)
		
	for child in get_children():
		if child is CollisionShape2D:
			coll_shape = child
			break

func _on_area_entered(area: Area2D) -> void:
	if not is_active:
		push_error("should be unreachable")
		return

	return 

	if area is Attack:
		if block_mode:
			area.block(self.stats)
		else:
			area.reduce(self.stats)
