class_name Parser extends RefCounted
## DialogueScript parser. 
## Takes an array of tokens as input and creates a list of statements

## The outputted list of parsed statements.
var lines: Array[DLine]

## The input token list.
var tokens: Array[Lexer.Line]

## List of required globals
var required_globals: Array[Script]
## List of required scripts. An instance of each must be given
var required_class_names: Array[Script]

# namespace variables
var scripts: Dictionary[String, Script]
var properties: Array[String]
var methods: Array[String]
var signals: Array[String]

## The idx of the first heading (i.e. after all the imports)
var body_start: int

## heading ids
var headings: Dictionary[String, int]
var labels: Dictionary[String, int]

var curr_id: int
var curr_heading: int
var curr_signals: Dictionary[String, int]
var curr_speaker: String

func _init(_tokens: Array[Lexer.Line]) -> void:
	lines = []
	tokens = _tokens
	required_globals = []
	required_class_names = []
	scripts = {}
	properties = []
	methods = []

func parse() -> Array[DLine]:
	add_labels()
	parse_imports()
	curr_id = body_start
	
	while curr_id < len(tokens) and tokens[curr_id].type == Lexer.LineType.HEADING:
		parse_heading_block()

	return lines

func throw_error(msg: String, line: Lexer.Line) -> void:
	push_error('Parser error "', msg, '" found in line ', str(line.line_num), 
				': "', line, '"')

func add_labels() -> void:
	for i in range(len(tokens)):
		var line := tokens[i]
		match line.type:
			Lexer.LineType.LABEL:
				labels[line.val as String] = i
			Lexer.LineType.HEADING:
				headings[line.val as String] = i
				labels[line.val as String] = i

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
		throw_error("Couldn't find a valid autoload called '" + name + "'", line)

	add_names(name, script, qualified)

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

## add members of the script to the namespace variables
func add_names(name: String, script: Script, qualified: bool) -> void:
	scripts[name] = script

	for property in script.get_script_property_list():
		if qualified:
			properties.append(name + "." + property.get("name"))
		else:
			properties.append(property.get("name"))

	for method in script.get_script_method_list():
		if qualified:
			methods.append(name + "." + method.get("name"))
		else:
			methods.append(method.get("name"))

	for sig in script.get_script_signal_list():
		if qualified:
			signals.append(name + "." + sig.get("name"))
		else:
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
				add_names(alias, script, true)
				required_class_names.append(script)

			Lexer.LineType.REQUIRE_USING:
				var script := find_script(line.val as String, line)
				add_names(line.val, script, false)
				required_class_names.append(script)
			_:
				body_start = i
				return

func valid_ident(name: String) -> bool:
	return scripts.has(name) or properties.has(name) or methods.has(name) or signals.has(name)

func get_label_id(name: String) -> int:
	if not labels.has(name):
		return -1
	return labels.get(name)

func add_line() -> void:
	lines.append(DLine.new(curr_id, DLine.Data.new(curr_heading, curr_signals)))

## Returns whether continue
func parse_heading_block() -> void:
	if tokens[curr_id].type != Lexer.LineType.HEADING:
		return
	
	curr_heading = headings.get(tokens[curr_id].val as String)
	curr_signals = {}
	curr_speaker = ""
	add_line()

	curr_id += 1

	while curr_id < len(tokens) and tokens[curr_id].type != Lexer.LineType.HEADING:
		var line := tokens[curr_id]
		match line.type:
			Lexer.LineType.LABEL:
				add_line()
			Lexer.LineType.CHARACTER:
				curr_speaker = line.val
			Lexer.LineType.JUMP:
				lines.append(DLine.Jump.new(curr_id, get_label_id(line.val), DLine.Data.new(curr_heading, curr_signals)))
			Lexer.LineType.JUMP_RET:
				pass
			Lexer.LineType.SIGNAL_JUMP:
				parse_signal()
			Lexer.LineType.LINE:
				if is_question():
					parse_response_set()
				else:
					if not curr_speaker:
						throw_error("No speaker defined at this line", tokens[curr_id])
					lines.append(DLine.Turn.new(curr_id, curr_speaker, line.val, DLine.Data.new(curr_heading, curr_signals)))
			Lexer.LineType.RESPONSE:
				push_error("Parser error should be unreacheable")
			
		curr_id += 1

func parse_signal() -> void:
	var line := tokens[curr_id]
	var sig := line.val[0] as String

	if not valid_ident(sig):
		throw_error("Could not find signal '" + str(sig) + "' in namespace", line)
	var label := get_label_id(line.val[1] as String)
	if label == -1:
		throw_error("Could not find label '" + str(line.val[1]) + "' in the file", line)

	curr_signals[sig] = label

func is_question() -> bool:
	if tokens[curr_id].type != Lexer.LineType.LINE or curr_id+1 == len(tokens):
		return false
	
	return tokens[curr_id+1].type == Lexer.LineType.RESPONSE

func parse_response_set() -> void:
	breakpoint


func display_debug() -> void:
	for line in lines:
		print(line)
