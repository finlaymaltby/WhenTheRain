extends Node

## function returns when the signal fires
func wait(s: Signal) -> void:
	await s

## waits for either the signal to fire or the timer to timeout.
## returns true if the signal fired
func wait_for(s: Object, name, time: float) -> bool:
	
	var ret_wait_or := Signal(self, "ret_wait_or")
	add_user_signal("ret_wait_or")
	var was_sig: bool
	
	var on_s = func(): 
		ret_wait_or.emit()
		was_sig = true
		
	var on_time = func(): 
		ret_wait_or.emit()
		was_sig = false
	
	s.connect(name, on_s)
	get_tree().create_timer(time).timeout.connect(on_time)
	
	await ret_wait_or
	
	s.disconnect(name, on_s)
	
	return was_sig
