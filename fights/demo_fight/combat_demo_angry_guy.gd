class_name CombatDemoAngryGuy extends CombatAngryGuy

@onready var already_smalltalked := false

var enemy_very_close: PEvent
var enemy_close: PEvent
var enemy_leaves: PEvent
var enemy_hit: PEvent
var self_hit: PEvent

func _ready() -> void:
	super()

	if not balloon:
		push_error("my balloon :(")
	
	
	enemy_very_close = PEvent.EnemyNear.new(state, DIST_V_CLOSE)
	enemy_close = PEvent.EnemyNear.new(state, DIST_CLOSE)
	enemy_leaves = PEvent.EnemyNotNear.new(state, DIST_CLOSE)
	enemy_hit = PEvent.EnemyDamaged.new(state)
	self_hit = PEvent.Damaged.new(state)

	enemy_hit.firing.connect(func(ev): print("hit hit hit"))
	dialogue = Dialogue.compile_from_raw(dialogue_path, [self, enemy_close], {})
	
	balloon.start(dialogue, "START")
	
	
	$OneWeaponManager.request_focus($OneWeaponManager/Sword)

func _process(delta: float) -> void:
	state.update.emit()
	

func get_move_dir() -> Vector2:
	return Vector2.ZERO
