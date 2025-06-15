class_name PEventHandler extends Resource

var event_listener: PEvent 
var overrides: Array[PEventHandler]
var on_fire: Callable

static func from(_listener: PEvent, _on_fire: Callable) -> PEventHandler:
	var handler := PEventHandler.new()
	handler.event_listener = _listener
	handler.on_fire = _on_fire
	return handler

func update(state: PEvent.State) -> void:
	event_listener.update(state)
	for e in overrides:
		e.update(state)

## checks for firing and calls on_fire
## returns whether it or any of its overrides fired
func run() -> bool:
	var has_fired := false
	for e in overrides:
		if e.run():
			has_fired = true

	if not has_fired:
		if event_listener.fired:
			on_fire.call()
			has_fired = true

	return has_fired

## Adds the event handler to list of overrides
func with_override(overriding_event: PEventHandler) -> PEventHandler:
	overrides.append(overriding_event)
	return self

func with_overrides(overriding_events: Array[PEventHandler]) -> PEventHandler:
	overrides.append_array(overriding_events)
	return self
