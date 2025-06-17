extends CombatCharacter

const DIST_V_CLOSE := 300
const DIST_CLOSE := 480

@export var dialogue: DialogueResource
@export var balloon: DialogueBalloon

## angy guy expecting you to attack?
@onready var is_prepped := false

var enemy_close := PEvent.EnemyNear.from_dist(DIST_CLOSE)

var handler: PEventHandler = tie(PEvent.Always.new(), default).with_overrides(
	[
		tie(PEvent.EnemyNear.from_dist(DIST_CLOSE).given(PEvent.EnemyAdvances.new()), func(): 
			balloon.jump_checked("_on_approach", dialogue)
			),
	]
)

func _ready() -> void:
	super()
	if not balloon:
		push_error("my balloon :(")
	if not dialogue: 
		push_error("my dialouge :(")
		
	balloon.start(dialogue, "start", [self])

func default() -> void:
	pass

func they_jump() -> void:
	print("you jumped")

func _process(delta: float) -> void:
	handler.update(state)
	handler.run()

func get_move_dir() -> Vector2:
	return Vector2.ZERO
	
func _physics_process(delta: float) -> void:
	var move_type := process_movement(delta)
	move_and_slide()
	
func _on_health_component_health_died(dmg_taken: float) -> void:
	queue_free()
