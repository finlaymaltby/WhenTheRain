class_name HurtBox extends Area2D

## The health component to do damage to
@export var health: HealthComponent

## the character to apply knockback to
@export var character: CombatBody

## health lost = damage_vec.dot(damage_weight)
## Represents what proportion of damage each damage type goes to health lost
## Because a statblock intends to represent every type of damage and everything has some vulnerability,
## The values should sum to 1 to represent the total vulnerabilties
## i.e. for a person (0.8,0.2)
@export var damage_weight: StatBlock

## minimum damage required to cause any damage to health
## effective damage = clamp(incoming damage - fortitude, 0, inf) 
@export var fortitude: float = 0

@export var coll_shape: CollisionShape2D

## impulse = damage_vec.dot(knockback_weight)
## What proportion of damage goes to knockback
## delta_v = (impulse/mass) 
## :: 100px per sec per mass per damage
@onready var knockback_weight := damage_weight.complement()

func _ready() -> void:
	if not character:
		if get_parent() is CombatBody:
			character = get_parent()
			health = character.health
		else:
			push_error("no character found onready")

	if not health:
		push_error("no health component found onready")
	
	if not damage_weight:
		push_error("no damage weight found onready")
	if not knockback_weight:
		push_error("no knockback weight found on ready")

	if not coll_shape:
		for child in get_children():
			if child is CollisionShape2D:
				coll_shape = child

	

## take a hit, applying damage and knockback in direction
func hit_me(damage: StatBlock, dir: Vector2) -> void:
	var d := damage.dot(damage_weight)
	d = clampf(d - fortitude, 0, INF)
	
	health.heal(-d)
	character.knockback(dir * damage.dot(knockback_weight))
	
## uses the body's fortitude to reduce the damage for the next thing, reducing it to zero
func reduce(damage: StatBlock) -> StatBlock:
	# calculate the amount of damage the hurt box would be able to withstand
	var dmg := damage.dot(damage_weight)
	var reduced := clampf(dmg - fortitude, 0, INF)

	var s := reduced/dmg

	assert((damage.times(s).dot(damage_weight)) == reduced)
	return damage.times(s)
