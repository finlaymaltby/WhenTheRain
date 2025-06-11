extends Node
class_name HealthComponent

signal health_changed(change: float)
signal health_died(change: float)

@export var max_health : float
var current_health : float 

func _ready() -> void:
	if max_health == 0:
		push_warning("max_health set to 0, did you mean to do this")
	current_health = max_health

func heal(health: float) -> void:
	health = clampf(health, -INF, max_health - current_health)
	current_health += health
	health_changed.emit(health)
	if current_health <= 0:
		health_died.emit(health)
