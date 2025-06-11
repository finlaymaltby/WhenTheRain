class_name testBrain extends CombatBrain

func _init() -> void:
	handler = tie(PEvent.Always.new(), nothing).override(
		tie(PEvent.EnemyNear.from_dist(400), on_near).override(
			tie(PEvent.EnemyNear.from_dist(200), too_near)
			)
		).override(
		tie(PEvent.EnemyAirborne.new(), aire)
		)

func nothing():
	pass

func on_near():
	pass

func too_near():
	pass

func aire():
	pass
