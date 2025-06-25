class_name Dialogue extends Node

signal interrupted

## The corresponding instance of the object referred to by the string name in the file
var object_bindings: Dictionary[String, Object]
var signal_bindings: Dictionary[String, Signal]
var _signal_arg_counts: Dictionary[String, int]

var res: DialogueResource

var _curr_id: int:
	set(val):
		update_interrupts(val)
		_curr_id = val

var _curr_line: DialogueLine:
	get:
		return res.lines[_curr_id]
	set(val):
		_curr_id = val.id
		_curr_line = val

var curr_turn: DialogueLine.Turn
var _curr_interrupts: Array[DialogueLine.Interrupt]

func _init(resource: DialogueResource, _object_bindings: Dictionary[String, Object]) -> void:
	res = resource
	object_bindings = _object_bindings

static func compile_from_raw(path: String, _unnamed_inputs: Array[Object], _named_inputs: Dictionary[String, Object]) -> Dialogue:
	var compiler := DialogueCompiler.from_path(path)
	for obj in _unnamed_inputs:
		compiler.add_using(obj)

	for key in _named_inputs:
		compiler.add_named_input(key, _named_inputs[key])

	compiler.compile()
	return compiler.dialogue

## Compile without any external variables
static func from_path(path: String) -> Dialogue:
	var compiler := DialogueCompiler.from_path(path)
	return compiler.compile()

func start_at(label: String) -> void:
	if not has_label(label):
		return 
	_curr_id = res.labels[label]

func next() -> void:
	if is_finished():
		return
	
	run_until_turn()

func run() -> void:
	_curr_id = _curr_line.next_id

	if _curr_line is DialogueLine.Mutation:
		await _curr_line.run_mutation(self)

func run_until_turn() -> void:
	while not is_finished():
		run()

		if _curr_line is DialogueLine.Turn:
			curr_turn = _curr_line
			return 

func get_responses() -> Array[DialogueLine.Response]:
	if not curr_turn is DialogueLine.Question:
		return []
	var responses: Array[DialogueLine.Response] = []
	for id in curr_turn.responses:
		var line := res.lines[id]
		if not line is DialogueLine.Response:
			push_error("An internal error has occured. Question line responses points to a non-turn")
		responses.append(line)
		
	return responses

func pick_response(response: DialogueLine.Response) -> void:
	print(response)
	_curr_id = response.id

func has_label(title: String) -> bool:
	return title in res.labels

func jump_end() -> void:
	_curr_id = DialogueScript.ID_END

func is_finished() -> bool:
	return _curr_id >= len(res.lines) or _curr_id == DialogueScript.ID_END

func update_interrupts(next_id: int) -> void:
	for interrupt in _curr_interrupts:
		signal_bindings[interrupt.signal_name].disconnect(_on_interrupt)

	for interrupt in res.lines[next_id].interrupts:
		var sig := signal_bindings[interrupt.signal_name]
		var args := _signal_arg_counts[interrupt.signal_name]
		sig.connect(_on_interrupt.bind(interrupt).unbind(args))

	_curr_interrupts = res.lines[next_id].interrupts

func _on_interrupt(interrupt: DialogueLine.Interrupt) -> void:
	interrupt.run_mutation(self)
	interrupted.emit()
