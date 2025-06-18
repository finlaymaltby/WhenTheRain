extends Label
class_name HealthDisplay

@export var character: CombatBody


func _process(delta: float) -> void:
	if character:
		text = str(round(character.health.current_health)) + "/" + str(round(character.health.max_health))
