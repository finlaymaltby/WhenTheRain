extends Attack
class_name MeleeAttack

@export var character: CombatBody

func _ready() -> void:
	super._ready()
	if not character:
		push_error("no character found")

func reduce(stop_stats: StatBlock) -> void:
	stats.reduce(stop_stats)
	if stats.is_zero():
		is_active = false
		reduced_to_zero.emit()
	
func block(shield: ShieldBox) -> void:
	stats.reduce(shield.stats)
	blocked.emit()
	is_active = false
