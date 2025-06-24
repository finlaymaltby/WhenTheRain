class_name Parser extends RefCounted
## DialogueScript parser. 
## Takes an array of tokens as input and creates a list of statements

## The created dialogue resource
var resource: DResource

## The input token list.
var tokens: Array[Lexer.Line]

# namespace variables
var properties: Array[String]
var methods: Array[String]
var signals: Array[String]

## The idx of the first heading (i.e. after all the imports)
var body_start: int

var curr_id: int
var curr_heading: int
var curr_signals: Dictionary[String, int]
var curr_speaker: String

func _init(_tokens: Array[Lexer.Line]) -> void:
	resource = DResource.empty()
	tokens = _tokens
	properties = []
	methods = []

func parse() -> DResource:
	add_labels()
	parse_imports()
	curr_id = body_start
	
	while curr_id < len(tokens) and tokens[curr_id].type == Lexer.LineType.HEADING:
		parse_heading_block()

	check_indentation()
	return resource

func throw_error(msg: String, line: Lexer.Line) -> void:
	push_error('Parser error "', msg, '" found in line ', str(line.line_num), 
				': "', line, '"')

func add_labels() -> void:
	for i in range(len(tokens)):
		var line := tokens[i]
		match line.type:
			Lexer.LineType.LABEL:
				resource.labels[line.val as String] = i
			Lexer.LineType.HEADING:
				resource.headings[line.val as String] = i
				resource.labels[line.val as String] = i

## Whether a qualified identifier is autoloaded, i.e. is an autoload or a member of one
func add_autoload(name: String, qualified: bool, line: Lexer.Line) -> void:
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
		breakpoint
		throw_error("Couldn't find a valid autoload called '" + name + "' (Project autoload section missing)", line)

	resource.add_global(script, name)
	add_names(name, script, qualified, line)

func find_script(name: String, line: Lexer.Line) -> Script:
	var base_script: Script = null

	for class_dict in ProjectSettings.get_global_class_list():
		if class_dict.get("class") == DScript.ident_head(name):
			base_script = load(class_dict.path)
	if not base_script:
		throw_error("Couldn't find class '" + DScript.ident_head(name) + "' in the global namespace", line)
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

func try_add_use(name: String, script_name: String, line: Lexer.Line):
	var err := resource.add_use(name, script_name)
	if err:
		throw_error(err, line)


## add members of the script to the namespace variables
func add_names(name: String, script: Script, qualified: bool, line: Lexer.Line) -> void:
	resource.add_script(name, script)
	
	var constant_map = script.get_script_constant_map()
	for key in constant_map:
		continue
		if constant_map[key] is Script:
			if qualified:
				add_names(name + "." + key, constant_map[key], true, line)
			else:
				try_add_use(key, name, line)
				add_names(key, constant_map[key], true, line)

	for property in script.get_script_property_list():
		if qualified:
			properties.append(name + "." + property.get("name"))
		else:
			try_add_use(property.get("name"), name, line)
			properties.append(property.get("name"))

	for method in script.get_script_method_list():
		if qualified:
			methods.append(name + "." + method.get("name"))
		else:
			try_add_use(method.get("name"), name, line)
			methods.append(method.get("name"))

	for sig in script.get_script_signal_list():
		if qualified:
			signals.append(name + "." + sig.get("name"))
		else:
			try_add_use(sig.get("name"), name, line)

			signals.append(sig.get("name"))

func parse_imports() -> void:
	for i in range(len(tokens)):

		var line := tokens[i]
		match line.type:
			Lexer.LineType.IMPORT:
				add_autoload(line.val as String, true, line)
			Lexer.LineType.IMPORT_USING:
				add_autoload(line.val as String, false, line)

			Lexer.LineType.REQUIRE:
				var alias := line.val[0] as String
				var script := find_script(line.val[1] as String, line)
				add_names(alias, script, true, line)
				resource.add_require(script, alias)

			Lexer.LineType.REQUIRE_USING:
				var script := find_script(line.val as String, line)
				add_names(line.val, script, false, line)
				resource.add_require(script, "")
			_:
				body_start = i
				return

func valid_ident(name: String) -> bool:
	return properties.has(name) or methods.has(name) or signals.has(name)

func get_label_id(name: String) -> int:
	if not resource.labels.has(name):
		throw_error("Could not find label '" + name + "' in the file", tokens[curr_id])
		return -1
	return resource.labels.get(name)

func get_curr_data() -> DLine.Data:
	return DLine.Data.new(curr_heading, curr_signals)

func add_label_line() -> void:
	resource.lines.append(DLine.new(curr_id, get_curr_data()))

## Returns whether continue
func parse_heading_block() -> void:
	if tokens[curr_id].type != Lexer.LineType.HEADING:
		return
	
	curr_heading = resource.headings.get(tokens[curr_id].val as String)
	curr_signals = {}
	curr_speaker = ""
	resource.lines.append(DLine.DLabel.new(curr_id, tokens[curr_id].val, get_curr_data()))

	curr_id += 1
	
	while curr_id < len(tokens) and tokens[curr_id].type != Lexer.LineType.HEADING:
		var line := tokens[curr_id]
		if parse_simple_line():
			continue

		match line.type:
			Lexer.LineType.SIGNAL_JUMP:
				parse_signal()
			Lexer.LineType.RESPONSE:
				push_error("Parser error should be unreacheable")
			_:
				throw_error("Unexpected line type in heading block", line)
			
		
## Parses lines that can appear anywhere: turns, jumps, labels, character swaps, etc.
func parse_simple_line() -> bool:
	var did_parse := true
	var line := tokens[curr_id]

	match line.type:
		Lexer.LineType.LABEL:
			resource.lines.append(DLine.DLabel.new(curr_id, tokens[curr_id].val, get_curr_data()))
		Lexer.LineType.CHARACTER:
			curr_speaker = line.val
		Lexer.LineType.JUMP:
			resource.lines.append(DLine.Jump.new(curr_id, get_label_id(line.val), get_curr_data()))
		Lexer.LineType.JUMP_RET:
			resource.lines.append(DLine.JumpRet.new(curr_id, get_label_id(line.val), get_curr_data()))
		Lexer.LineType.LINE:
			if not curr_speaker:
				throw_error("No speaker defined at this line", tokens[curr_id])
			if is_question():
				parse_question()
			else:
				resource.lines.append(DLine.Turn.new(curr_id, curr_speaker, line.val, get_curr_data()))
		_:
			did_parse = false
	
	if did_parse:
		curr_id += 1

	return did_parse

func parse_signal() -> void:
	var line := tokens[curr_id]
	var sig := line.val[0] as String

	if not valid_ident(sig):
		throw_error("Could not find signal '" + str(sig) + "' in namespace", line)
		return
	var label := get_label_id(line.val[1] as String)
	if label == -1:
		
		return

	curr_signals[sig] = label
	curr_id += 1

func is_question() -> bool:
	if tokens[curr_id].type != Lexer.LineType.LINE or curr_id+1 == len(tokens):
		return false
	
	return tokens[curr_id+1].type == Lexer.LineType.RESPONSE

func parse_question() -> void:
	var line := tokens[curr_id]
	var responses: Array[int] = []
	resource.lines.append(DLine.Question.new(curr_id, curr_speaker, line.val, responses, get_curr_data()))
	curr_id += 1

	while curr_id < len(tokens):
		var response_id := parse_response()
		if response_id != -1:
			responses.append(response_id)
		else:
			break


## Parses a response and returns its starting id. Returns -1 if none found
func parse_response() -> int:
	if tokens[curr_id].type != Lexer.LineType.RESPONSE:
		return -1

	var response: String = tokens[curr_id].val
	var response_id := curr_id
	var response_indent := tokens[curr_id].indent
	resource.lines.append(DLine.Response.new(curr_id, response, get_curr_data()))
	curr_id += 1

	while tokens[curr_id].indent > response_indent and curr_id < len(tokens):
		var line := tokens[curr_id]
		if parse_simple_line():
			continue
		else: 
			throw_error("Unexpected line type in response block", line)
			return -1

	return response_id

func check_indentation() -> void:
	for i in range(len(tokens)-1):
		if tokens[i].type == Lexer.LineType.RESPONSE:
			continue
		if tokens[i].indent < tokens[i+1].indent:
			throw_error("Unexpected indent occurs at this line", tokens[i+1])

func display_debug() -> void:
	for line in resource.lines:
		print(line)
