class_name DParser extends RefCounted
## DialogueScript parser. 
## Takes an array of tokens as input and creates a list of statements

## The created dialogue resource
var resource: DialogueResource
var was_successful: bool
## The input token list.
var tokens: Array[DLexer.Line]

# namespace variables
var properties: Array[String]
var methods: Array[String]
var signals: Array[String]
# Stores paths of objects whose properties can't be accessed for static type analysis
var opaque_paths: Array[String] = []

## The idx of the first heading (i.e. after all the imports)
var body_start: int
const skipped_line_types := [DLexer.LineType.IMPORT, DLexer.LineType.REQUIRE,
							 DLexer.LineType.REQUIRE_USING, DLexer.LineType.CHARACTER, DLexer.LineType.INTERRUPT]

var curr_idx: int
var curr_heading: int
var curr_interrupts: Dictionary[String, DialogueLine.Interrupt]
var curr_speaker: String

func _init(_tokens: Array[DLexer.Line], _resource: DialogueResource = null) -> void:
	if not _resource:
		resource = DialogueResource.empty()
	was_successful = true
	tokens = _tokens
	properties = []
	methods = []

func parse() -> DialogueResource:
	add_labels()
	parse_imports()
	curr_idx = body_start
	
	while curr_idx < len(tokens) and tokens[curr_idx].type == DLexer.LineType.HEADING:
		parse_heading_block()
		resource.lines[-1].next_id = DialogueScript.ID_END

	check_indentation()
	return resource

func throw_error(msg: String, line: DLexer.Line = null) -> void:
	if not line:
		line = tokens[curr_idx]

	push_error('DParser error "', msg, '" found in line ', str(line.line_num), 
				': "', line, '"')

	was_successful = false

func add_labels() -> void:
	for i in range(len(tokens)):
		var line := tokens[i]
		match line.type:
			DLexer.LineType.LABEL:
				resource.labels[line.val as String] = get_label_id(line.val)
			DLexer.LineType.HEADING:
				resource.labels[line.val as String] = get_label_id(line.val)

## Whether a qualified identifier is autoloaded, i.e. is an autoload or a member of one
func add_autoload(name: String, qualified: bool, line: DLexer.Line) -> void:
	var script: Script = null
	var project := ConfigFile.new()
	project.load("res://project.godot")

	if project.has_section("autoload"):
		var keys := project.get_section_keys("autoload")
		if name not in keys:
			throw_error("Couldn't find a valid autoload called '" + name + "'", line)
			return
		var path = project.get_value("autoload", name)
		script = load(path.right(-1))
	else:
		throw_error("Couldn't find a valid autoload called '" + name + "' (Project autoload section missing)", line)

	resource.add_global(script, name)
	add_names(name, script, qualified, line)

func find_script(name: String, line: DLexer.Line) -> Script:
	var base_script: Script = null

	for class_dict in ProjectSettings.get_global_class_list():
		if class_dict.get("class") == DialogueScript.ident_head(name):
			base_script = load(class_dict.path)
	if not base_script:
		throw_error("Couldn't find class '" + DialogueScript.ident_head(name) + "' in the global namespace", line)
		return null
		
	var names := name.split(".")
	
	if len(names) == 1:
		return base_script

	var curr_script := base_script
	
	for i in range(1, len(names)):
		var constants := curr_script.get_script_constant_map()
		var next = constants.get(names[i])

		if next is Script:
			curr_script = next
		else:
			throw_error("Couldn't find a class named '" + names[i] + "' in " + names[i-1], line)

	return curr_script

## add members of the script to the namespace variables
func add_names(name: String, script: Script, qualified: bool, line: DLexer.Line) -> void:
	resource.add_script(name, script)
	
	var constant_map = script.get_script_constant_map()
	for key in constant_map:
		continue
		if constant_map[key] is Script:
			if qualified:
				add_names(name + "." + key, constant_map[key], true, line)

			else:
				add_names(key, constant_map[key], true, line)

	for property in script.get_script_property_list():
		if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			var prop_name: String = name + "." + property.name if qualified else property.name
			properties.append(prop_name)
			if property.type == TYPE_OBJECT: # doesn't carry script info so it cannot be verified
				opaque_paths.append(prop_name) 

	for method in script.get_script_method_list():
		var method_name: String = name + "." + method.name if qualified else method.name
		methods.append(method_name)
	
	for sig in script.get_script_signal_list():
		var signal_name: String = name + "." + sig.name if qualified else sig.name
		signals.append(signal_name)

func parse_imports() -> void:
	for i in range(len(tokens)):
		var line := tokens[i]
		match line.type:
			DLexer.LineType.IMPORT:
				add_autoload(line.val as String, true, line)

			DLexer.LineType.REQUIRE:
				var alias := line.val[0] as String
				var script := find_script(line.val[1] as String, line)
				add_names(alias, script, true, line)
				resource.add_require(script, alias)
			DLexer.LineType.REQUIRE_USING:
				var script := find_script(line.val as String, line)
				add_names(line.val, script, false, line)
				var err := resource.add_require_using(script)
				if err:
					throw_error(err, line)
			_:
				body_start = i
				return

func valid_name(name: String) -> bool:
	for opaque in opaque_paths:
		if name.begins_with(opaque):
			return true # default to true if it is not possible to analyse the validity of a property
	return properties.has(name) or methods.has(name) or signals.has(name)

func get_obj_name(name: String) -> String:
	if not valid_name(name):
		throw_error("Cannot access object of invalid name")

	var head := DialogueScript.ident_head(name)

	if head in resource._script_map.keys():
		return head

	return ""

func get_property_path(name: String) -> String:
	if not valid_name(name):
		throw_error("Cannot access property path of invalid name")

	var head := DialogueScript.ident_head(name)

	if head in resource._script_map.keys():
		return (name.replace(".", ":") as NodePath).get_concatenated_subnames()

	return name.replace(".", ":")

func get_label_id(name: String) -> int:
	var id := 0
	for line in tokens:
		if line.val is String and line.val == name:
			if line.type == DLexer.LineType.LABEL or line.type == DLexer.LineType.HEADING:
				return id
		
		if not skipped_line_types.has(line.type):
			id += 1
	
	if name == "END":
		return DialogueScript.ID_END
	throw_error("Could not find label '" + name + "' in the file", tokens[curr_idx])
	return -1

func get_curr_id() -> int:
	return len(resource.lines)

func add_label_line() -> void:
	resource.lines.append(DialogueLine.new(get_curr_id(), curr_interrupts.values()))

## Returns whether continue
func parse_heading_block() -> void:
	if tokens[curr_idx].type != DLexer.LineType.HEADING:
		return
	
	curr_heading = get_curr_id()
	curr_interrupts = {}
	curr_speaker = ""
	resource.lines.append(DialogueLine.Title.new(get_curr_id(), tokens[curr_idx].val, curr_interrupts.values()))

	curr_idx += 1
	
	while curr_idx < len(tokens) and tokens[curr_idx].type != DLexer.LineType.HEADING:
		var line := tokens[curr_idx]
		if parse_simple_line():
			continue

		match line.type:
			DLexer.LineType.INTERRUPT:
				parse_interrupt()
			DLexer.LineType.RESPONSE:
				push_error("DParser error should be unreacheable")
			_:
				throw_error("Unexpected line type in heading block", line)
				curr_idx += 1
			
		
## Parses lines that can appear anywhere: turns, jumps, labels, character swaps, etc.
func parse_simple_line() -> bool:
	var did_parse := true
	var line := tokens[curr_idx]

	match line.type:
		DLexer.LineType.LABEL:
			resource.lines.append(DialogueLine.Title.new(get_curr_id(), tokens[curr_idx].val, curr_interrupts.values()))
			curr_idx += 1
		DLexer.LineType.CHARACTER:
			curr_speaker = line.val
			curr_idx += 1
		DLexer.LineType.SET:
			parse_set()
		DLexer.LineType.EXECUTE:
			parse_execute()
		DLexer.LineType.JUMP:
			resource.lines.append(DialogueLine.Jump.new(get_curr_id(), get_label_id(line.val), curr_interrupts.values()))
			curr_idx += 1
		DLexer.LineType.JUMP_RET:
			resource.lines.append(DialogueLine.JumpRet.new(get_curr_id(), get_label_id(line.val), curr_interrupts.values()))
			curr_idx += 1
		DLexer.LineType.TURN:
			if not curr_speaker:
				throw_error("No speaker defined at this line", tokens[curr_idx])
			if is_question():
				parse_question()
			else:
				resource.lines.append(DialogueLine.Turn.new(get_curr_id(), curr_speaker, line.val, curr_interrupts.values()))
				curr_idx += 1
		_:
			did_parse = false
		
	return did_parse

func parse_interrupt() -> void:
	var line := tokens[curr_idx]
	var signal_name := line.val[0] as String

	if not valid_name(signal_name):
		throw_error("Could not find signal '" + str(signal_name) + "' in namespace", line)
		curr_idx += 1
		return

	var label := get_label_id(line.val[1] as String)
	var interrupt := DialogueLine.InterruptJump.new(
		get_obj_name(signal_name), 
		get_property_path(signal_name), 
		label)

	curr_interrupts[signal_name] = interrupt
	curr_idx += 1

func parse_set() -> void:
	var line := tokens[curr_idx]
	var var_path := line.val[0] as String
	if not valid_name(var_path):
		throw_error("Could not find variable '" + var_path + "' in namespace", line)
		curr_idx += 1
		return

	var value := Expression.new()
	var err := value.parse(line.val[1], resource._script_map.keys())
	if err != OK:
		throw_error("Expression parse error: '" + value.get_error_text()+ "'", line)

	resource.lines.append(
		DialogueLine.Set.new(
			get_curr_id(), 
			get_obj_name(var_path), 
			get_property_path(var_path),
			value,
			curr_interrupts.values()))

	curr_idx += 1

func parse_execute() -> void:
	var line := tokens[curr_idx]
	var expr := Expression.new()
	var err := expr.parse(line.val, resource._script_map.keys())
	if err != OK:
		throw_error("Expression parse error: '" + expr.get_error_text()+ "'", line)
		
	resource.lines.append(
		DialogueLine.Execute.new(
			get_curr_id(), 
			expr, 
			curr_interrupts.values()))

	curr_idx += 1

func is_question() -> bool:
	if tokens[curr_idx].type != DLexer.LineType.TURN or curr_idx+1 == len(tokens):
		return false
	
	return tokens[curr_idx+1].type == DLexer.LineType.RESPONSE

func parse_question() -> void:
	var line := tokens[curr_idx]
	var responses: Array[int] = []
	resource.lines.append(
		DialogueLine.Question.new(
			get_curr_id(), 
			curr_speaker, 
			line.val, 
			responses, 
			curr_interrupts.values()))

	curr_idx += 1

	while curr_idx < len(tokens):
		var response_id := parse_response()
		if response_id != -1:
			responses.append(response_id)
		else:
			break
	
	if len(responses) < 2:
		return
	for i in range(1, len(responses)):
		var id := responses[i]-1
		resource.lines[id].next_id = len(resource.lines)

## Parses a response and returns its starting id. Returns -1 if none found
func parse_response() -> int:
	if tokens[curr_idx].type != DLexer.LineType.RESPONSE:
		return -1

	var response: String = tokens[curr_idx].val
	var response_id := get_curr_id()
	var response_indent := tokens[curr_idx].indent
	resource.lines.append(
		DialogueLine.Response.new(
			get_curr_id(), 
			response, 
			curr_interrupts.values()))
			
	curr_idx += 1
	
	while curr_idx < len(tokens) and tokens[curr_idx].indent > response_indent:
		var line := tokens[curr_idx]
		if parse_simple_line():
			continue
		else: 
			throw_error("Unexpected line type in response block", line)
			curr_idx += 1
			return -1
	
	return response_id

func check_indentation() -> void:
	for i in range(len(tokens)-1):
		if tokens[i].type == DLexer.LineType.RESPONSE:
			continue
		if tokens[i].indent < tokens[i+1].indent:
			throw_error("Unexpected indent occurs at this line", tokens[i+1])

func display_debug() -> void:
	for line in resource.lines:
		print(line)
