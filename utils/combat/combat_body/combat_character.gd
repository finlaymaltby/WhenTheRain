class_name CombatCharacter extends CombatBody

## The enemy for fight targeting
@export var enemy: CombatBody

## the dialogue reading out
@export var dialogue: DialogueResource

## balloon to display dialogue to
@export var balloon: DialogueBalloon

var state: PEvent.State 

var _jump_titles: Dictionary[PEvent, String]

func _ready() -> void:
	super()
	
	if not enemy:
		push_error("enemy msut be dfined")
	state = PEvent.State.new(self, enemy)

	health.health_died.connect(_on_health_died)

func _physics_process(delta: float) -> void:
	var _move_type := process_movement(delta)
	move_and_slide()
	
func tie(event: PEvent, on_fire: Callable) -> PEventHandler:
	return PEventHandler.new(event, on_fire)

func _on_health_died(dmg_taken: float) -> void:
	queue_free()

func handle_jump(event: PEvent) -> void:
	if not event.fired:
		push_error("firing func was called when event didn't fire??")
	
	balloon.jump_checked(_jump_titles[event], dialogue)

func set_jump_when(event: PEvent, title: String) -> void:
	if not event.firing.is_connected(handle_jump):
		event.firing.connect(handle_jump)
	
	_jump_titles[event] = title

func unset_jump_when(event: PEvent, title: String) -> void:
	event.firing.disconnect(handle_jump)
	_jump_titles[event] = ""