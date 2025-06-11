class_name CombatBrain extends Resource

func tie(event: PEvent, on_fire: Callable) -> PEventHandler:
	return PEventHandler.from(event, on_fire)

var handler: PEventHandler = tie(PEvent.Always.new(), nothing).override(
		tie(PEvent.EnemyNear.from_dist(200), on_near)
	).override(
		tie(PEvent.EnemyAirborne.new(), aire)
	)

func update_and_run(state: PEvent.State) -> void:
	handler.update(state)
	handler.run()

func nothing():
	print("nothing is happening")

func on_near():
	print("aah you're close")

func aire():
	print("youre in the air!")
