class_name Attack extends Area2D

signal reduced_to_zero
signal blocked

## The stats the attack starts with
@export var max_stats: StatBlock
@export var is_active: bool = true:
	set(value):
		if value and not is_active:
			activate()
			
		is_active = value
		set_deferred("monitorable", is_active)
		set_deferred("monitoring", is_active)
		
var stats : StatBlock
var already_hit: Array[HurtBox] = []

func _ready() -> void:
	if max_stats == null:
		push_error("no max_stats found onready")

	
func activate() -> void:
	stats = max_stats.duplicate()
	already_hit = []

func _physics_process(delta: float) -> void:
	if not is_active:
		return

	for area in get_overlapping_areas():
		if area is HurtBox and has_los(area) and (area not in already_hit):
			var dir := global_transform.basis_xform(Vector2.RIGHT)
			area.hit_me(stats, dir)
			already_hit.append(area)

func has_los(area: Area2D) -> bool:
	var ray := RayCast2D.new()
	add_child(ray)
	ray.collide_with_areas = true
	ray.collision_mask = 0
	ray.set_collision_mask_value(4,true)
	ray.target_position = global_transform.inverse() * area.global_position
	ray.enabled = true
	ray.force_raycast_update()
	

	if ray.is_colliding():
		var obj = ray.get_collider()
		ray.queue_free()
		return obj == area
	ray.queue_free()
	return true

func reduce(stop_stats: StatBlock) -> void:
	stats.reduce(stop_stats)
	if stats.is_zero():
		is_active = false
		reduced_to_zero.emit()

	
func block(shield: ShieldBox) -> void:
	push_error("should be defined in inherited class")
	blocked.emit()
