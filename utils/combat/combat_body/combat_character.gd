class_name CombatCharacter extends CombatBody

@export var enemy: CombatBody

var state: PEvent.State 

func _ready() -> void:
	super._ready()
	
	if not enemy:
		push_error("enemy msut be dfined")
	state = PEvent.State.from(self, enemy)

func _physics_process(delta: float) -> void:
	var _move_type := process_movement(delta)
	move_and_slide()
	
func tie(event: PEvent, on_fire: Callable) -> PEventHandler:
	return PEventHandler.from(event, on_fire)

func _on_health_component_health_died(dmg_taken: float) -> void:
	queue_free()
