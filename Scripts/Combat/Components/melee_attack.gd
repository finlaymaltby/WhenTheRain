extends Attack
class_name MeleeAttack

@export var character: CombatBody

func _ready() -> void:
	super._ready()
	if not character:
		push_error("no character found")

func block(shield: ShieldBox) -> void:
	stats.reduce(shield.stats)
	blocked.emit()
	is_active = false
