class_name DLexer extends RefCounted
## DialogueScript lexer. 
## Not a conventional lexer because it treats each line as 'token',
## which is possible because there is no recursion within each line

class Line extends RefCounted:
	var type: LineType
	var val: Variant
	var line_num: int
	var indent: int 

	func _init(_type: LineType, _val: Variant, _line_num: int, _indent: int = -2) -> void:
		type = _type
		val = _val
		line_num = _line_num
		indent = _indent

	func _to_string() -> String:
		var string := "%3d: @" % line_num + "%d " % indent
		match type:
			LineType.IMPORT:
				string += "IMPORT ||" + str(val) + "||"
			LineType.REQUIRE:
				string += "REQUIRE |" + str(val[0]) + "| AS ||" + str(val[1]) + "||"
			LineType.REQUIRE_USING:
				string += "REQUIRE USING ||" + str(val) + "||"
			LineType.HEADING:
				string += "HEADING |" + str(val) + "|"
			LineType.LABEL:
				string += "LABEL |" + str(val) + "|"
			LineType.CHARACTER:
				string += 'CHARACTER "' + val + '"'
			LineType.SET:
				string += "SET ||" + str(val[0]) + "|| = " + str(val[1])
			LineType.EXECUTE:
				string += 'EXECUTE "' + str(val) + '"'
			LineType.JUMP:
				string += "JUMP |" + str(val) + "|"
			LineType.JUMP_RET:
				string += "JUMP RET |" + str(val) + "|"
			LineType.INTERRUPT:
				string += "WHEN ||" + str(val[0]) + "|| JUMP |" + str(val[1]) + "|"
			LineType.TURN:
				string += 'TURN "' + val + '"'
			LineType.RESPONSE:
				string += 'RESPONSE "' + val + '"'

		return string

enum LineType {
	IMPORT,
	REQUIRE,
	REQUIRE_USING,

	HEADING,
	LABEL,
	CHARACTER,
	SET,
	EXECUTE,
	
	JUMP,
	JUMP_RET,
	INTERRUPT,

	TURN,
	RESPONSE
}

## Array of outputted tokenised lines
var tokens: Array[Line]
## Input text
var text: String
## Lines of text.
var lines: PackedStringArray
var was_successful: bool

## The current line number.
var curr_line_num: int
## The line currently being processed
var curr_line: String
## The indent of the line currently beign processed
var curr_indent: int

var indented_with_spaces: bool
var indented_with_tabs: bool

func _init(_text: String) -> void:
	tokens = []
	text = _text
	lines = text.split("\n")
	curr_line_num = 1
	was_successful = true

	indented_with_spaces = false
	indented_with_tabs = false

func tokenise() -> Array[Line]:
	while curr_line_num - 1 < len(lines):
		curr_indent = 0
		curr_line = lines[curr_line_num-1]
		create_line()
		curr_line_num += 1

	return tokens

func throw_error(msg: String, line_num: int = -1, line: String = "") -> void:
	if line_num == -1:
		line_num = curr_line_num
	if not line:
		line = lines[curr_line_num-1]
	push_error('DLexer error "', msg, '" found in line ', str(line_num), 
				': "', line, '"')
	was_successful = false

## Process and create the current line
func create_line() -> void:
	remove_comments()

	if len(curr_line.strip_edges()) == 0:
		return

	while consume_indents():
		pass
		
	if consume_once("import"):
		skip_spaces()
		if consume_once("using"):
			throw_error("Import using statement not supported at the moment")
			return
		else:
			if not make_line_with_ident(LineType.IMPORT):
				throw_error("Expected identifer to follow import statement")

	elif consume_once("require"):
		skip_spaces()
		if consume_once("using"):
			skip_spaces()
			if not make_line_with_qualified_ident(LineType.REQUIRE_USING):
				throw_error("Expected qualfied identifer to follow import statement")
		else:
			var ident := consume_ident()
			if ident.is_empty():
				throw_error("Expected identifier to follow require statement")
			skip_spaces()
			if not consume_once("as"):
				throw_error("Expected 'as' keyword to follow identifier in require statement")
			skip_spaces()
			var sig := consume_qualified_ident()
			if sig.is_empty():
				throw_error("Expected qualified identifer for the classtype in require using statement")
			make_line(LineType.REQUIRE, [ident, sig])

	elif consume_once("*"):
		skip_spaces()
		make_line(LineType.CHARACTER, consume_string().strip_edges())

	elif consume_once("~"):
		skip_spaces()
		if not make_line_with_ident(LineType.LABEL):
			throw_error("Expected label identifer to follow label symbol")

	elif consume_once("-"):
		skip_spaces()
		make_line(LineType.RESPONSE, consume_string().strip_edges())

	elif consume_once("$"):
		skip_spaces()
		var ident := consume_qualified_ident()
		if ident.is_empty():
			throw_error("Expected qualified identifier to follow set symbol")
		skip_spaces()
		if not consume_once("="):
			throw_error("Expected equal sign to follow identifier in set statement")
		skip_spaces()
		var expr := consume_string()
		make_line(LineType.SET, [ident, expr])

	elif consume_once("!"):
		skip_spaces()
		var expr := consume_string()
		make_line(LineType.EXECUTE, expr)

	elif consume_once("=><"):
		skip_spaces()
		if not make_line_with_ident(LineType.JUMP_RET):
			throw_error("Expected label identifer to follow jump return symbol")

	elif consume_once("=>"):
		skip_spaces()
		if not make_line_with_ident(LineType.JUMP):
			throw_error("Expected label identifer to follow jump symbol")

	elif consume_once("?"):
		skip_spaces()
		var sig := consume_qualified_ident()
		if sig.is_empty():
			throw_error("Expected qualified identifer as signal in interrupt statement")
		skip_spaces()
		if not consume_once("=>"):
			throw_error("Expected jump symbol in interrupt statement")
		skip_spaces()
		var label = consume_ident()
		if label.is_empty():
			throw_error("Expected identifer as label in interrupt statement")
		make_line(LineType.INTERRUPT, [sig, label])

	elif consume_some("="):
		skip_spaces()
		var heading = consume_ident()
		if heading.is_empty():
			throw_error("Expected identifer in heading")
		skip_spaces()
		consume_some("=")
		make_line(LineType.HEADING, heading)

	else:
		var line_text := consume_string()
		make_line(LineType.TURN, line_text)

	expect_eol()
	return 

## Consume any spaces at the current start of the line
func skip_spaces() -> void:
	curr_line = curr_line.lstrip(" ")

## Consumes any indents at the start of the line given by tabs or spaces
func consume_indents() -> bool:
	var space_trimmed := curr_line.lstrip(" ")
	var spaces_removed := curr_line.length() - space_trimmed.length()
	
	if spaces_removed > 0:
		curr_line = space_trimmed
		indented_with_spaces = true
		if indented_with_tabs:
			throw_error("Line indented with spaces in a file with tab indents")
	
	var tab_trimmed := curr_line.lstrip("\t")
	var tabs_removed := curr_line.length() - tab_trimmed.length()
	
	if tabs_removed > 0:
		curr_line = tab_trimmed
		indented_with_tabs = true
		if indented_with_spaces:
			throw_error("Line indented with tabs in a file with space indents")

	curr_indent += spaces_removed + tabs_removed
	return spaces_removed + tabs_removed > 0

## Removes any comments at the end of the line
func remove_comments() -> void:
	var idx = curr_line.find("#")
	if idx != -1:
		curr_line = curr_line.left(idx)
	
## Attempts to consume the given prefix once, returning true if successful
func consume_once(prefix: String) -> bool:
	if not curr_line.begins_with(prefix): return false
	curr_line = curr_line.trim_prefix(prefix)
	return true

## A one or more consume. Returns true if prefix was consumed at least once.
func consume_some(prefix: String) -> bool:
	if not curr_line.begins_with(prefix): return false

	while curr_line.begins_with(prefix):
		curr_line = curr_line.trim_prefix(prefix)
	
	return true

## Consumes the entirety of the current line.
## Duplicates and returns the line, setting curr_line to ""
func consume_string() -> String:
	var result := String(curr_line)
	curr_line = ""
	return result

## Make a line and append it to tokens with curr_line_num and curr_indent
func make_line(type: LineType, val: Variant) -> void:
	tokens.append(Line.new(type, val, curr_line_num, curr_indent))
	

## Try to consume an indent and make a line with it as the value
func make_line_with_ident(type: LineType) -> bool:
	var ident := consume_ident()
	if ident.is_empty():
		return false
		
	make_line(type, ident)
	return true

## Consumes an identifier from the line and returns it. Returns "" if none is found.
func consume_ident() -> String:
	var n: int = 1
	while n <= len(curr_line) and curr_line.left(n).is_valid_ascii_identifier():
		n += 1
		
	if n == 1:
		return ""
	
	var ident := curr_line.left(n-1)
	curr_line = curr_line.right(-(n-1))
	return ident

## Consumes a qualified indentifer from the line and returns it
func consume_qualified_ident() -> String:
	var qualified_ident := ""

	var ident: = consume_ident()
	if not ident: return qualified_ident
	qualified_ident += ident

	if not consume_once("."):
		return qualified_ident

	while true:
		ident = consume_ident()
		if not ident: 
			throw_error("Qualified indentifier cannot end in a period")
		qualified_ident += "." + ident

		if not consume_once("."): 
			return qualified_ident
	
	push_error("Error in lexer. Should be unreacheable.")
	return qualified_ident

## Try to consume an indent and make a line with it as the value
func make_line_with_qualified_ident(type: LineType) -> bool:
	var qualified_ident := consume_qualified_ident()
	if not qualified_ident:
		return false
		
	make_line(type, qualified_ident)
	return true

## Expect the line to be finished. Throws an error if anything other than a comment or whitespace is found
func expect_eol() -> void:
	skip_spaces()
	if curr_line.length() != 0:
		throw_error("Expected end of line but found '" + curr_line + "' instead")
	
	curr_line = ""
	
func display_debug() -> void:
	for line in tokens:
		print(line)

		
