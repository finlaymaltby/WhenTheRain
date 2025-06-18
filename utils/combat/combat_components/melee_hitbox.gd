class_name MeleeHitbox extends HitBox

signal parried

## The stats the attack starts with
@export var max_stats: DamageStats

## does the attack pierce through bodies that aren't listed on teh physical body layer
@export var pierce: bool = true

## Whether the attack is currently active and 
@export var is_active: bool = true:
	set(value):
		if value and not is_active:
			already_hit = []
			
		is_active = value
		set_deferred("monitorable", is_active)
		set_deferred("monitoring", is_active)
	
## The hurt boxes that have already been damaged by the attack
var already_hit: Array[HurtBox] = []
## the ray used to detect los 
var ray: RayCast2D

func _ready() -> void:
	if not max_stats:
		push_error("no max_stats found onready")

	ray = RayCast2D.new()
	add_child(ray)
	ray.collide_with_areas = true
	ray.collide_with_bodies = true
	ray.collision_mask = 0
	# set the ray to collide with hurtboxes and physical objects
	ray.set_collision_mask_value(3,true)
	ray.set_collision_mask_value(4,true)
	ray.exclude_parent = true
	ray.hit_from_inside = false
	ray.enabled = false

func _physics_process(delta: float) -> void:
	if not is_active:
		return

	for area in get_overlapping_areas():
		if area is HurtBox and (area not in already_hit):
			try_hit(area)

## attemps to hit the hurtbox, by testing if it has los and if so, making it take damage
func try_hit(hurt: HurtBox) -> void:
	# aim ray at target
	ray.position = Vector2.ZERO
	ray.target_position = global_transform.inverse() * hurt.global_position

	var stats := max_stats.duplicate()
	ray.enabled = true

	while true:
		ray.force_raycast_update()
		if not ray.is_colliding():
			push_error("something went wrong here, check ray collision")
		
		var obj = ray.get_collider()
		
		if not obj is HurtBox:
			# hitting something we can't damage
			return 
		obj = obj as HurtBox

		# test if hitting the target
		if obj == hurt: 
			break

		if obj.get_collision_layer_value(4) or (obj.get_collision_layer_value(3) and pierce):
			stats = obj.reduce(stats)
			if stats.is_zero():
				# attack has been entirely blocked
				return
		
		# stop the ray from colliding with this object again and keep going
		ray.add_exception(obj)
	
		
	# if reached the end of loop, we must have hit the object
	var dir := global_transform.basis_xform(Vector2.RIGHT)
	hurt.hit_me(stats, dir)
	already_hit.append(hurt)
	ray.enabled = false
	ray.clear_exceptions()

func parry(shield: ShieldBox) -> void:
	push_error("should be defined in inherited class")
	parried.emit()
