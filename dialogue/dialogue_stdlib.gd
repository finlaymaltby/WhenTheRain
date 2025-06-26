extends Node

## function returns when the signal fires
func until(sig: Signal) -> void:
	await sig

## waits for either the signal to fire or the timer to timeout.
## returns true if the signal fired
func until_or_wait(obj: Object, sig: StringName, time: float) -> bool:
	var ret_until_or_wait := Signal(self, "ret_until_or_wait")
	add_user_signal("ret_until_or_wait", [{ "name": "was_signal", "type": TYPE_BOOL }])
	
	var on_sig = func(): 
		ret_until_or_wait.emit(true)
		
	var on_time = func(): 
		ret_until_or_wait.emit(false)
		
	obj.connect(sig, on_sig)
	var timer := get_tree().create_timer(time)
	timer.timeout.connect(on_time)
	
	var was_sig: bool = await ret_until_or_wait
	
	obj.disconnect(sig, on_sig)
	timer.timeout.disconnect(on_time)
	remove_user_signal("ret_until_or_wait")
	return was_sig

## wait until the state event occurs, returning immediately if it is already occuring
func when_or_wait(event: PEvent.StateEvent, time: float) -> bool:
	if event.occurred:
		return true

	var ret_when_or_wait := Signal(self, "ret_when_or_wait")
	add_user_signal("ret_when_or_wait", [{ "name": "was_signal", "type": TYPE_BOOL }])
	
	var on_sig = func(e): 
		ret_when_or_wait.emit(true)
		
	var on_time = func(): 
		ret_when_or_wait.emit(false)
		
	event.firing.connect(on_sig)
	var timer := get_tree().create_timer(time)
	timer.timeout.connect(on_time)
	
	var was_sig: bool = await ret_when_or_wait
	
	event.firing.disconnect(on_sig)
	timer.timeout.disconnect(on_time)
	remove_user_signal("ret_when_or_wait")
	return was_sig
