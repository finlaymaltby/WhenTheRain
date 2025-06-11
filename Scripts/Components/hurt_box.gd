extends Area2D
class_name HurtBox


## The health component to damage to
@export var health: HealthComponent
## the character to apply knockback to
@export var character: CombatBody
## health lost = damage_vec.dot(damage_weight)
## Represents what proportion of damage goes to health lost
## Should sum to 1
## i.e. for a person (0.8,0.2)
@export var damage_weight: StatBlock
## impulse = damage_vec.dot(knockback_weight)
## What proportion of damage goes to knockback
@onready var knockback_weight := damage_weight.complement()
const KNOCKBACK_SCALE = 100

func _ready() -> void:
	if not health:
		push_error("no health component found onready")
	if not character:
		push_error("no character found onready")
	if not damage_weight:
		push_error("no damage weight found onready")
	if not knockback_weight:
		push_error("no knockback weight found on ready")
		
	if damage_weight.sum() != 1:
		push_warning("damage weight should sum to 1 to be convenient")
	if knockback_weight.sum() != 1:
		push_warning("knockback weight should sum to 1 to be convenient")
		
func hit_me(damage: StatBlock, dir: Vector2) -> void:
	health.heal(-damage.dot(damage_weight))
	character.knockback(dir * damage.dot(knockback_weight) * KNOCKBACK_SCALE)
	
	
