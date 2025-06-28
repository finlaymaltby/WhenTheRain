class_name DParser extends RefCounted
## DialogueScript parser. 
## Takes an array of lines as input and creates a list of statements

## The created dialogue resource
var resource: DialogueResource
var was_successful: bool
## The input token list.
var lines: Array[DLexer.Line]

# namespace variables
var name_space: Array[String]
# Stores paths of objects whose properties can't be accessed for static type analysis
var opaque_paths: Array[String] = []

## The idx of the first heading (i.e. after all the imports)
var body_start: int
## The types of lines that won't becmoe DialogueLines, so they are skipped when calculating line_ids 
const skipped_line_types := [DLexer.LineType.IMPORT, DLexer.LineType.IMPORT_AS, DLexer.LineType.REQUIRE,
							 DLexer.LineType.REQUIRE_USING, DLexer.LineType.CHARACTER, DLexer.LineType.INTERRUPT]

var curr_idx: int
var curr_line: DLexer.Line:
	get:
		return lines[curr_idx]


var curr_heading: int
var curr_interrupts: Dictionary[String, DialogueLine.Interrupt]
var curr_speaker: String

func _init(_lines: Array[DLexer.Line], _resource: DialogueResource = null) -> void:
	if not _resource:
		resource = DialogueResource.empty()
	was_successful = true
	lines = _lines
	name_space = []

func parse() -> DialogueResource:
	add_labels()
	parse_imports()
	curr_idx = body_start
	
	while curr_idx < len(lines) and curr_line.type == DLexer.LineType.HEADING:
		parse_heading_block()
		if resource.lines[-1].next_id_override == Dialogue.ID_UNDEF:
			resource.lines[-1].next_id_override = Dialogue.ID_END

	validate_indentation()
	validate_jump_label_ids()
	return resource

func throw_error(msg: String, line: DLexer.Line = null) -> void:
	if not line:
		line = curr_line

	push_error('DParser error "', msg, '" found in line ', str(line.line_num), 
				': "', line, '"')

	was_successful = false

func get_curr_id() -> int:
	return len(resource.lines)

#region preprocessing and imports 

func add_labels() -> void:
	for i in range(len(lines)):
		match lines[i].type:
			DLexer.LineType.LABEL:
				resource.titles[lines[i].val as String] = get_label_id(lines[i].val)
			DLexer.LineType.HEADING:
				resource.titles[lines[i].val as String] = get_label_id(lines[i].val)

## Given an identifier finds the corresponding global script
func find_global_script(global_name: String, line: DLexer.Line) -> Script:
	var script: Script = null
	var project := ConfigFile.new()
	project.load("res://project.godot")

	if project.has_section("autoload"):
		var keys := project.get_section_keys("autoload")
		if global_name not in keys:
			throw_error("Couldn't find a valid autoload called '" + global_name + "'", line)
			return
		var path = project.get_value("autoload", global_name)
		script = load(path.right(-1))
	else:
		throw_error("Couldn't find a valid autoload called '" + global_name + "' (Project autoload section missing)", line)

	return script

## Given a qualified identifier finds the corresonding class script
func find_class_script(classname: String, line: DLexer.Line) -> Script:
	var base_script: Script = null

	for class_dict in ProjectSettings.get_global_class_list():
		if class_dict.get("class") == Dialogue._ident_head(classname):
			base_script = load(class_dict.path)
	if not base_script:
		throw_error("Couldn't find class '" + Dialogue._ident_head(classname) + "' in the global namespace", line)
		return null
		
	var segments := classname.split(".")
	
	if len(segments) == 1:
		return base_script

	var curr_script := base_script
	
	for i in range(1, len(segments)):
		var constants := curr_script.get_script_constant_map()
		var next = constants.get(segments[i])

		if next is Script:
			curr_script = next
		else:
			throw_error("Couldn't find a class named '" + segments[i] + "' in " + segments[i-1], line)

	return curr_script

func add_to_namespace(path: String) -> void:
	if path in name_space:
		throw_error("Namespace collision has occurred with path '" + path + "'")
	name_space.append(path)

## add script and script members to the namespace variables
func add_members(alias: String, script: Script, qualified: bool) -> void:
	# because members a
	var added_already: Array[String] = []
	add_to_namespace(alias)

	var constant_map = script.get_script_constant_map()
	for key in constant_map:
		if not constant_map[key] is Script:
			var prop_path: String = alias + "." + key if qualified else key
			if prop_path not in added_already:
				add_to_namespace(prop_path)
				added_already.append(prop_path)

	for prop_dict in script.get_script_property_list():
		if prop_dict.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			var prop_path: String = alias + "." + prop_dict.name if qualified else prop_dict.name
			if prop_path not in added_already:
				add_to_namespace(prop_path)
				added_already.append(prop_path)

			if prop_dict.type == TYPE_OBJECT: # doesn't carry script info so it cannot be verified
				opaque_paths.append(prop_path) 

	for method_dict in script.get_script_method_list():
		var method_path: String = alias + "." + method_dict.name if qualified else method_dict.name
		if method_path not in added_already:
			add_to_namespace(method_path)
			added_already.append(method_path)
	
	for signal_dict in script.get_script_signal_list():
		var signal_path: String = alias + "." + signal_dict.name if qualified else signal_dict.name
		if signal_path not in added_already:
			add_to_namespace(signal_path)
			added_already.append(signal_path)

func parse_imports() -> void:
	for i in range(len(lines)):
		var line := lines[i]
		match line.type:
			DLexer.LineType.IMPORT:
				var global_name := line.val as String
				var script := find_global_script(global_name, line)
				resource.add_global(script, global_name)
				add_members(global_name, script, true)
			DLexer.LineType.IMPORT_AS:
				var global_name := line.val[0] as String
				var alias := line.val[1] as String
				var script := find_global_script(global_name, line)
				resource.add_global(script, alias)
				add_members(global_name, script, true)

			DLexer.LineType.REQUIRE:
				var classname := line.val[0] as String
				var alias := line.val[1] as String
				var script := find_class_script(classname, line)
				add_members(alias, script, true,)
				resource.add_require(script, alias)
			DLexer.LineType.REQUIRE_USING:
				var classname := line.val as String
				var script := find_class_script(classname, line)
				add_members(line.val, script, false)
				var err := resource.add_require_using(script)
				if err:
					throw_error(err, line)
			_:
				body_start = i
				return

#endregion

func get_label_id(name: String) -> int:
	var id := 0
	for line in lines:
		if line.val is String and line.val == name:
			if line.type == DLexer.LineType.LABEL or line.type == DLexer.LineType.HEADING:
				return id
		
		if not skipped_line_types.has(line.type):
			id += 1
	
	if name == "END":
		return Dialogue.ID_END
	throw_error("Could not find label '" + name + "' in the file", curr_line)
	return Dialogue.ID_UNDEF

func valid_name(name: String) -> bool:
	for opaque in opaque_paths:
		if name.begins_with(opaque):
			return true # default to true if it is not possible to analyse the validity of a property
	return name_space.has(name)

func get_head_segment(name: String) -> String:
	if not valid_name(name):
		throw_error("Cannot access object of invalid name")

	var head := Dialogue._ident_head(name)

	if head in resource.aliases:
		return head

	return ""

func get_sub_segments(name: String) -> String:
	if not valid_name(name):
		throw_error("Cannot access property path of invalid name")

	var head := Dialogue._ident_head(name)

	if head in resource.aliases:
		return (name.replace(".", ":") as NodePath).get_concatenated_subnames()

	return name.replace(".", ":")

func parse_heading_block() -> void:
	if curr_line.type != DLexer.LineType.HEADING:
		return
	
	curr_heading = get_curr_id()
	curr_interrupts = {}
	curr_speaker = ""
	resource.lines.append(
		DialogueLine.Title.new(get_curr_id(), curr_line.val, curr_interrupts.values())
	)

	curr_idx += 1
	
	while curr_idx < len(lines) and curr_line.type != DLexer.LineType.HEADING:
		if parse_simple_line():
			continue

		match curr_line.type:
			DLexer.LineType.INTERRUPT:
				parse_interrupt()
			DLexer.LineType.RESPONSE:
				push_error("DParser error should be unreacheable")
			_:
				throw_error("Unexpected line type in heading block", curr_line)
				curr_idx += 1
			
		
## Parses lines that can appear anywhere: turns, jumps, labels, character swaps, etc.
func parse_simple_line() -> bool:
	var did_parse := true

	match curr_line.type:
		DLexer.LineType.LABEL:
			resource.lines.append(
				DialogueLine.Title.new(get_curr_id(), curr_line.val, curr_interrupts.values())
			)
			curr_idx += 1
		DLexer.LineType.CHARACTER:
			curr_speaker = curr_line.val
			curr_idx += 1
		DLexer.LineType.SET:
			parse_set()
		DLexer.LineType.EXECUTE:
			parse_execute()
		DLexer.LineType.JUMP:
			resource.lines.append(
				DialogueLine.Jump.new(get_curr_id(), get_label_id(curr_line.val), curr_interrupts.values())
			)
			curr_idx += 1
		DLexer.LineType.JUMP_RET:
			resource.lines.append(
				DialogueLine.JumpRet.new(get_curr_id(), get_label_id(curr_line.val), curr_interrupts.values())
			)
			curr_idx += 1
		DLexer.LineType.IF:
			parse_if_block()
		DLexer.LineType.ELSE:
			throw_error("Did not expect else without preceding if", curr_line)
			curr_idx += 1
		DLexer.LineType.TURN:
			if not curr_speaker:
				throw_error("No speaker defined at this line", curr_line)
			if is_question():
				parse_question()
			else:
				resource.lines.append(
					DialogueLine.Turn.new(get_curr_id(), curr_speaker, curr_line.val, curr_interrupts.values())
				)
				curr_idx += 1
		_:
			did_parse = false
		
	return did_parse

func parse_interrupt() -> void:
	var signal_name := curr_line.val[0] as String

	if not valid_name(signal_name):
		throw_error("Could not find signal '" + str(signal_name) + "' in namespace", curr_line)
		curr_idx += 1
		return

	var label := get_label_id(curr_line.val[1] as String)
	var interrupt := DialogueLine.InterruptJump.new(
		get_head_segment(signal_name), 
		get_sub_segments(signal_name), 
		label
	)

	curr_interrupts[signal_name] = interrupt
	curr_idx += 1

func parse_set() -> void:
	var lvalue := curr_line.val[0] as String
	if not valid_name(lvalue):
		throw_error("Could not find variable '" + lvalue + "' in namespace", curr_line)
		curr_idx += 1
		return

	var value := Expression.new()
	var err := value.parse(curr_line.val[1], resource.aliases)
	if err != OK:
		throw_error("Expression parse error: '" + value.get_error_text()+ "'", curr_line)

	resource.lines.append(
		DialogueLine.Set.new(
			get_curr_id(), 
			get_head_segment(lvalue), 
			get_sub_segments(lvalue),
			value,
			curr_interrupts.values()))

	curr_idx += 1

func parse_execute() -> void:
	var expr := Expression.new()
	var err := expr.parse(curr_line.val, resource.aliases)
	if err != OK:
		throw_error("Expression parse error: '" + expr.get_error_text()+ "'", curr_line)
		
	resource.lines.append(
		DialogueLine.Execute.new(
			get_curr_id(), 
			expr, 
			curr_interrupts.values()))

	curr_idx += 1

func is_question() -> bool:
	if curr_line.type != DLexer.LineType.TURN or curr_idx+1 == len(lines):
		return false
	
	return lines[curr_idx+1].type == DLexer.LineType.RESPONSE

func parse_question() -> void:
	var responses: Array[int] = []
	resource.lines.append(
		DialogueLine.Question.new(
			get_curr_id(), 
			curr_speaker, 
			curr_line.val, 
			responses, 
			curr_interrupts.values())
	)

	curr_idx += 1

	while curr_idx < len(lines):
		var response_id := parse_response()
		if response_id != Dialogue.ID_UNDEF:
			responses.append(response_id)
		else:
			break
	
	if len(responses) < 2:
		return

	for i in range(1, len(responses)):
		var id := responses[i]-1
		if resource.lines[id].next_id_override == Dialogue.ID_UNDEF:
			resource.lines[id].next_id_override = len(resource.lines)

func consume_block(ident: int):
	while curr_idx < len(lines) and curr_line.indent > ident:
		if parse_simple_line():
			continue
		else: 
			throw_error("Unexpected line type in block", curr_line)
			curr_idx += 1

## Parses a response and returns its starting id. Returns Dialogue.ID_UNDEF if none found
func parse_response() -> int:
	if curr_line.type != DLexer.LineType.RESPONSE:
		return Dialogue.ID_UNDEF

	var response: String = curr_line.val
	var response_id := get_curr_id()
	var response_indent := curr_line.indent
	resource.lines.append(
		DialogueLine.Response.new(
			get_curr_id(), 
			response, 
			curr_interrupts.values())
	)
			
	curr_idx += 1
	consume_block(response_indent)
	return response_id

func parse_if_block() -> bool:
	if curr_line.type != DLexer.LineType.IF:
		return false
	
	var if_id := get_curr_id()
	var if_indent := curr_line.indent
	var expr := Expression.new()
	var err := expr.parse(curr_line.val, resource.aliases)
	if err != OK:
		throw_error("Expression parse error: '" + expr.get_error_text()+ "'", curr_line)

	resource.lines.append(
		DialogueLine.If.new(
			if_id,
			expr,
			Dialogue.ID_UNDEF,
			curr_interrupts.values()
		)
	)

	curr_idx += 1
	consume_block(if_indent)
	resource.lines[if_id].else_id  = get_curr_id()
	
	if curr_idx == len(lines) or curr_line.type != DLexer.LineType.ELSE:
		return true

	var else_id := get_curr_id()
	resource.lines.append(
		DialogueLine.Else.new(
			get_curr_id(),
			curr_interrupts.values()
		)
	)
	curr_idx += 1
	consume_block(if_indent)
	if resource.lines[else_id - 1].next_id_override == Dialogue.ID_UNDEF:
			resource.lines[else_id - 1].next_id_override = get_curr_id()

	return true

func validate_indentation() -> void:
	for i in range(len(lines)-1):
		if lines[i].type == DLexer.LineType.HEADING:
			continue
		if lines[i].type == DLexer.LineType.RESPONSE:
			continue
		if lines[i].type in [DLexer.LineType.IF, DLexer.LineType.ELSE]:
			continue
		if lines[i].indent < lines[i+1].indent:
			throw_error("Unexpected indent occurs at this line", lines[i+1])

func validate_jump_label_ids() -> void:
	for line in resource.lines:
		if not line is DialogueLine.Jump:
			continue
		var jump_id = line.next_id_override
		if jump_id != Dialogue.ID_END and not resource.lines[jump_id] is DialogueLine.Title:
			push_error("Internal parser error has occurred. Jump id '" + str(jump_id) + "' does not point to a title")


func display_debug() -> void:
	for line in resource.lines:
		print(line)
