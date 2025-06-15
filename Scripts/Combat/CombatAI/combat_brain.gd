class_name CombatBrain extends Node

@export var body: CombatCharacter 

func _ready() -> void:
	if not body:
		if get_parent() is CombatCharacter:
			push_warning("assuming parent is body")
			body = get_parent()
		else:
			push_error("no body :(")

func tie(event: PEvent, on_fire: Callable) -> PEventHandler:
	return PEventHandler.from(event, on_fire)

var handler: PEventHandler

func _process(delta: float) -> void:
	handler.run()

func update_and_run(state: PEvent.State) -> void:
	handler.update(state)
	handler.run()
