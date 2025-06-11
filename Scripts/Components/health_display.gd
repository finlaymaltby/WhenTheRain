extends Label
class_name HealthDisplay

@export var character: CombatBody

func _ready() -> void:
	label_settings = preload("res://Resources/health_display_font.tres")
func _process(delta: float) -> void:
	if character:
		text = str(round(character.health.current_health)) + "/" + str(round(character.health.max_health))
