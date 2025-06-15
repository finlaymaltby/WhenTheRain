class_name PEvent extends RefCounted

class State extends RefCounted: 
	var body: CombatBody
	var enemy: CombatBody

	static func from(self_body: CombatBody, enemy_body: CombatBody) -> State:
		var state := State.new()
		state.body = self_body
		state.enemy = enemy_body
		return state

	func position() -> Vector2:
		return body.global_position

	func velocity() -> Vector2:
		return body.velocity

	func enemy_position() -> Vector2:
		return enemy.global_position

	func enemy_velocity() -> Vector2:
		return enemy.velocity
		
	func get_dist() -> float:
		return (position() - enemy_position()).length()
	
	func is_valid() -> bool:
		return body and enemy


## Did the event fire (off to on) in the most recently processed update.
## A conditioned event only fires if its signalling event is the one that fired.
## fired => occured
var fired: bool

## Call before accessing variables (e.g. occured and just_occured) on the current frame.
## Should only be updated ONCE per frame
func update(state: State) -> void:
	push_error("must be overriden in subclass")

## Class for events governed by a state that flips on and off.
## fires when off to on
class StateEvent extends PEvent:
	## Did the event occur, hold true in the most recently processed update
	var occured: bool

	## Did occured fire (off to on) in the most recently processed update
	## Use if you want to know the event occured and hasn't been processed yet.
	## Otherwise see triggered
	var just_occured: bool

	func update(state: State) -> void:
		var prev: bool = occured
		occured = _is_occurring(state)
		if not prev and occured:
			just_occured = true
		else:
			just_occured = false
		
		if occured:
			fired = _decide_fired(state)
		else:
			fired = false

	## Is the event occuring in the given state.
	## Must be overrided in subclass
	func _is_occurring(state: State) -> bool:
		breakpoint
		push_error("override in subclass")
		return false

	## Decide whether the event is 'firing' in the given state.
	## Called at the end of update, so occured and just_occured are valid.
	## Default is fired = just_occured, override if subclass is picky
	func _decide_fired(state: State) -> bool:
		return just_occured

## class for events that remember outside signals
class SignalEvent extends PEvent:
	## Stores when the signal fires. Is reset every frame
	var signal_fired_last: bool

	func _init(state: State) -> void:
		push_error("override and connect signal to _on_signal")

	func update(state: State) -> void:
		fired = signal_fired_last
		signal_fired_last = false

	func _on_signal() -> void:
		signal_fired_last = true

## Always occuring, use for root
class Always extends PEvent:
	func update(state: State) -> void:
		fired = true

func given(condition: StateEvent) -> Given:
	return Given.from(self, [condition])

func givens(conditions: Array[StateEvent]) -> Given:
	return Given.from(self, conditions)
	
## Class to handle signals equipped with extra conditions.
## Only occurs is all conditions are met.
## main event determins exactly when 'triggered'
class Given extends PEvent:
	## the main event
	var _main: PEvent
	## the additional conditions required to occur
	var _conditions: Array[StateEvent]
	
	static func from(main_event: PEvent, conditions: Array[StateEvent]) -> Given:
		var event := Given.new()
		event._main = main_event
		event._conditions = conditions
		return event
		
	func update(state: State) -> void:
		_main.update(state)
		for condition in _conditions:
			condition.update(state)
		
		fired = _main.fired and _conditions.all(func(c): return c._is_occurring(state))

class EnemyNear extends StateEvent:
	var near_dist: float 

	static func from_dist(dist: float) -> EnemyNear:
		var event := EnemyNear.new()
		event.near_dist = dist
		return event

	func _is_occurring(state: State) -> bool:
		return state.get_dist() <= near_dist
		
class EnemyAirborne extends StateEvent:
	func _is_occurring(state: State) -> bool:
		return not state.enemy.is_on_floor()

class EnemyAdvances extends StateEvent:
	func within_dist(dist: float) -> Given:
		var adv := EnemyAdvances.new()
		var dst := EnemyNear.from_dist(dist)
		return dst.given(adv)

	func _is_occurring(state: State) -> bool:
		return sign(state.position().x - state.enemy_position().x) == sign(state.enemy_velocity().x)

class EnemyRetreats extends StateEvent:
	func _is_occurring(state: State) -> bool:
		return sign(state.position().x - state.enemy_position().x) == -sign(state.enemy_velocity().x)

class HealthDied extends SignalEvent:
	func _init(state: State) -> void:
		state.body.health.health_died.connect(_on_signal)

class Damaged extends SignalEvent:
	func _init(state: State) -> void:
		state.body.health.health_changed.connect(_on_health_change)
	
	func _on_health_change(change: float) -> void:
		if change < 0:
			signal_fired_last = true

class Healed extends SignalEvent:
	func _init(state: State) -> void:
		state.body.health.health_changed.connect(_on_health_change)
	
	func _on_health_change(change: float) -> void:
		if change > 0:
			signal_fired_last = true

class EnemyDamaged extends SignalEvent:
	func _init(state: State) -> void:
		state.body.health.health_changed.connect(_on_health_change)
	
	func _on_health_change(change: float) -> void:
		if change < 0:
			signal_fired_last = true

class EnemyHealed extends SignalEvent:
	func _init(state: State) -> void:
		state.body.health.health_changed.connect(_on_health_change)
	
	func _on_health_change(change: float) -> void:
		if change > 0:
			signal_fired_last = true

class EnemyDied extends SignalEvent:
	func _init(state: State) -> void:
		state.enemy.died.connect(_on_signal)
