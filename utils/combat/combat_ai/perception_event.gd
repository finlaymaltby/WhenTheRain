class_name PEvent extends RefCounted

signal firing(event: PEvent)

const chicken := 5

class State extends RefCounted: 
	signal update

	var body: CombatBody
	var enemy: CombatBody

	func _init(self_body: CombatBody, enemy_body: CombatBody) -> void:
		body = self_body
		enemy = enemy_body

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

func _init(_state: State) -> void:
	state = _state
	state.update.connect(update)

## Reference to state to _update with
var state: State

## Did the event fire (off to on) in the most recently processed update.
## A conditioned event only fires if its signalling event is the one that fired.
## fired => occured
var fired: bool

## Call before accessing variables (e.g. occured and just_occured) on the current frame.
## Should only be updated ONCE per frame
func update() -> void:
	_update()
	if fired:
		firing.emit(self)

## override in subclass
func _update() -> void:
	push_error("must be overriden in subclass")

## Class for events governed by a state that flips on and off.
## fires when off to on
class StateEvent extends PEvent:
	## Did the event occur, hold true in the most recently processed _update
	var occurred: bool

	## Did occured fire (off to on) in the most recently processed _update
	## Use if you want to know the event occured and hasn't been processed yet.
	## Otherwise see triggered
	var just_occurred: bool

	func _update() -> void:
		var prev: bool = occurred
		occurred = _is_occurring()
		if not prev and occurred:
			just_occurred = true
		else:
			just_occurred = false
		
		if occurred:
			fired = _decide_fired()
		else:
			fired = false

	## Is the event occuring in the given state.
	## Must be overrided in subclass
	func _is_occurring() -> bool:
		push_error("override in subclass")
		return false

	## Decide whether the event is 'firing' in the given state.
	## Called at the end of _update, so occured and just_occured are valid.
	## Default is fired = just_occured, override if subclass is picky
	func _decide_fired() -> bool:
		return just_occurred

## class for events that remember outside signals
class SignalEvent extends PEvent:
	## Stores when the signal fires. Is reset every frame
	var signal_fired_last: bool

	func _update() -> void:
		fired = signal_fired_last
		signal_fired_last = false

	func _on_signal() -> void:
		signal_fired_last = true

## Always occuring, use for root
class Always extends PEvent:
	func _update() -> void:
		fired = true

func given(condition: StateEvent) -> Given:
	return Given.new(self, [condition])

func givens(conditions: Array[StateEvent]) -> Given:
	return Given.new(self, conditions)
	
## Class to handle signals equipped with extra conditions.
## Only occurs is all conditions are met.
## main event determins exactly when 'triggered'
class Given extends PEvent:
	## the main event
	var _main: PEvent
	## the additional conditions required to occur
	var _conditions: Array[StateEvent]
	
	func _init(main_event: PEvent, conditions: Array[StateEvent]) -> void:
		state = main_event.state
		_main = main_event
		_conditions = conditions
		state.update.connect(update)
		
	func _update() -> void:
		fired = _main.fired and _conditions.all(func(c): return c.occurred)

class EnemyNear extends StateEvent:
	var near_dist: float 

	func _init(_state: State, dist: float) -> void:
		super(_state)
		near_dist = dist

	func _is_occurring() -> bool:
		return state.get_dist() <= near_dist

class EnemyNotNear extends StateEvent:
	var near_dist: float 

	func _init(_state: State, dist: float) -> void:
		super(_state)
		near_dist = dist

	func _is_occurring() -> bool:
		return state.get_dist() > near_dist

class EnemyAirborne extends StateEvent:
	func _is_occurring() -> bool:
		return not state.enemy.is_on_floor()

class EnemyAdvances extends StateEvent:
	func _is_occurring() -> bool:
		return sign(state.position().x - state.enemy_position().x) == sign(state.enemy_velocity().x)

class EnemyRetreats extends StateEvent:
	func _is_occurring() -> bool:
		return sign(state.position().x - state.enemy_position().x) == -sign(state.enemy_velocity().x)

class HealthDied extends SignalEvent:
	func _init(_state: State) -> void:
		super(_state)
		state.body.health.health_died.connect(_on_signal)

class Damaged extends SignalEvent:
	func _init(_state: State) -> void:
		super(_state)
		state.body.health.health_changed.connect(_on_health_change)
	
	func _on_health_change(change: float) -> void:
		if change < 0:
			signal_fired_last = true

class Healed extends SignalEvent:
	func _init(_state: State) -> void:
		super(_state)
		state.body.health.health_changed.connect(_on_health_change)
	
	func _on_health_change(change: float) -> void:
		if change > 0:
			signal_fired_last = true

class EnemyDamaged extends SignalEvent:
	func _init(_state: State) -> void:
		super(_state)
		state.body.health.health_changed.connect(_on_health_change)
	
	func _on_health_change(change: float) -> void:
		if change < 0:
			signal_fired_last = true

class EnemyHealed extends SignalEvent:
	func _init(_state: State) -> void:
		super(_state)
		state.body.health.health_changed.connect(_on_health_change)
	
	func _on_health_change(change: float) -> void:
		if change > 0:
			signal_fired_last = true

class EnemyDied extends SignalEvent:
	func _init(_state: State) -> void:
		super(_state)
		state.enemy.died.connect(_on_signal)
