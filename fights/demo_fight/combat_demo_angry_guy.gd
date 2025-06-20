extends CombatAngryGuy

## angy guy expecting you to attack?
@onready var is_prepped := false


var enemy_very_close: PEvent
var enemy_close: PEvent
var enemy_leaves: PEvent


func _ready() -> void:
	super()
	if not balloon:
		push_error("my balloon :(")
	if not dialogue: 
		push_error("my dialouge :(")

	enemy_very_close = PEvent.EnemyNear.new(state, DIST_V_CLOSE)
	enemy_close = PEvent.EnemyNear.new(state, DIST_CLOSE)
	enemy_leaves = PEvent.EnemyNotNear.new(state, DIST_CLOSE)

	balloon.start(dialogue, "start", [self])
	
	get_tree().create_timer(2).timeout.connect(swing)

func _process(delta: float) -> void:
	state.update.emit()

func do(event):
	balloon.jump_checked("on_approach", dialogue)


func get_move_dir() -> Vector2:
	return Vector2.ZERO
