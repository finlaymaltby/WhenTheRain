class_name HealthComponent extends Node

signal health_changed(change: float)
signal health_died(change: float)

@export var max_health: float
var current_health: float 
var is_dead: bool

func _ready() -> void:
	if max_health == 0:
		push_warning("max_health set to 0, did you mean to do this")
	current_health = max_health
	is_dead = false

func heal(health: float) -> void:
	health = clampf(health, -INF, max_health - current_health)
	current_health += health
	health_changed.emit(health)
	if current_health <= 0 and not is_dead:
		health_died.emit(health)
		is_dead = true
