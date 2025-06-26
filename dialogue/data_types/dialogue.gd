class_name Dialogue extends Node

#region utils

const ID_END: int = -1
const AUTO_WAIT_TIME: float = 1

static func _is_ident(s: String) -> bool:
	return s.is_valid_ascii_identifier()

static func _ident_head(ident: String) -> String:
	return ident.split(".")[0]

static func _ident_last(ident: String) -> String:
	return ident.split(".")[-1]

static func _expr_to_string(expr: Expression) -> String:
	return "EXPR"

#endregion

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

## Set the dialogue to begin at the given label
## Call next_turn
func start_at(label: String) -> void:
	if not has_label(label):
		return 
	_curr_id = res.titles[label]

func next_turn() -> void:
	if is_finished():
		return
	
	_run_until_turn()

func _run_until_turn() -> void:
	while not is_finished():
		_run()

		if _curr_line is DialogueLine.Turn:
			curr_turn = _curr_line
			return

func _run() -> void:
	_curr_id = _curr_line.next_id

	if _curr_line is DialogueLine.Mutation:
		await _curr_line.run_mutation(self) 

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
	_curr_id = response.id

func has_label(title: String) -> bool:
	return title in res.titles

func jump_end() -> void:
	_curr_id = Dialogue.ID_END

func is_finished() -> bool:
	return _curr_id >= len(res.lines) or _curr_id == Dialogue.ID_END

func update_interrupts(next_id: int) -> void:
	for interrupt in _curr_interrupts:
		signal_bindings[interrupt.signal_path].disconnect(_on_interrupt)

	for interrupt in res.lines[next_id].interrupts:
		var sig := signal_bindings[interrupt.signal_path]
		var args := _signal_arg_counts[interrupt.signal_path]
		sig.connect(_on_interrupt.bind(interrupt).unbind(args))

	_curr_interrupts = res.lines[next_id].interrupts

func _on_interrupt(interrupt: DialogueLine.Interrupt) -> void:
	interrupt.run_mutation(self)
	interrupted.emit()
