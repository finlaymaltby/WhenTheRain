class_name HurtBox extends Area2D

## The health component to do damage to
@export var health: HealthComponent

## the character to apply knockback to
@export var character: CombatBody

## health lost = damage_vec.dot(damage_weight)
## Represents what proportion of damage each damage type goes to health lost
## i.e. for a person (0.95,0.4)
@export var damage_weight: StatBlock

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
		
func hit_me(damage: StatBlock, dir: Vector2) -> void:
	health.heal(-damage.dot(damage_weight))
	character.knockback(dir * damage.dot(knockback_weight))
	
	
