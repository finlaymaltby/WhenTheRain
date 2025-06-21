class_name Lexer extends RefCounted
## Lexer that takes a text as a string and returns a list of tokens

class Token extends RefCounted:
	var type: TokenType
	var val: Variant

	func _init(_type, _val = null) -> void:
		type = _type
		val = _val

enum TokenType {
	IDENT,
	STRING,
	NEWLINE,

	# imports
	IMPORT,
	USING,

	# symbols
	ASTERIX,
	BRACKET_LEFT,
	BRACKET_RIGHT,
	EQUALS,
	HYPHEN,
	PERIOD,
	TILDE,

	# symbol combinations
	JUMP, 
	JUMP_RET,
}

## the array of tokens that can be outputted
var tokens: Array[Token]
var _text: String
var _lines: PackedStringArray

func _init(text: String) -> void:
	_text = text
	_lines = text.split("\n")

func tokenise() -> Array[Token]:
	while len(_lines) > 0:
		var line: String = get_line()
		process_line(line)
		tokens.append(Token.new(TokenType.NEWLINE))

	return tokenise()

## consume and return first line of the text
func get_line() -> String:
	var line = _lines[0]
	_lines = _lines.slice(1)
	return line

func process_line(line: String) -> void:
	line = line.strip_edges()
	if consume_once("import", line):
		tokens.append(Token.new(TokenType.IMPORT))
		line = line.strip_edges()
		if consume_once("using", line):
			tokens.append(Token.new(TokenType.USING))
			line = line.strip_edges()
		if not add_ident(line):
			push_error("TODO ADD ERROR SUSTEM")
	elif consume_once("*", line):
		tokens.append(Token.new(TokenType.ASTERIX))
		line = line.strip_edges()
		var name = consume_until("#", line)
		tokens.append(Token.new(TokenType.STRING, name))
	elif consume_once("~", line):
		tokens.append(Token.new(TokenType.TILDE))
		line = line.strip_edges()
		if not add_ident(line):
			push_error("TODO ADD ERROR SUSTEM")
	elif consume_once("-", line):
		tokens.append(Token.new(TokenType.HYPHEN))
		line = line.strip_edges()
		var name = consume_until("#", line)
		tokens.append(Token.new(TokenType.STRING, name))
	elif consume_once("=><", line):
		tokens.append(Token.new(TokenType.JUMP_RET))
		if not add_ident(line):
			push_error("TODO ADD ERROR SUSTEM")
	elif consume_once("=>", line):
		tokens.append(Token.new(TokenType.JUMP))
		if not add_ident(line):
			push_error("TODO ADD ERROR SUSTEM")
	elif consume_some("=", line):
		tokens.append(Token.new(TokenType.EQUALS))
		line = line.strip_edges()
		if not add_ident(line):
			push_error("TODO ADD ERROR SUSTEM")
		line = line.strip_edges()
		if consume_some("=", line):
			tokens.append(Token.new(TokenType.EQUALS))
	else:
		var line_text := consume_until("#", line)
		tokens.append(Token.new(TokenType.STRING, line_text))

	expect_eol(line)
	return 

## attempts to consume the given prefix, returning true if successful
func consume_once(prefix: String, line: String) -> bool:
	if not line.begins_with(prefix): return false
	line = line.trim_prefix(prefix)
	return true

## one or more
func consume_some(prefix: String, line: String) -> bool:
	if not line.begins_with(prefix): return false

	while line.begins_with(prefix):
		line = line.trim_prefix(prefix)
	
	return true

## consumes until it reaches the character, not including it. Returns full string if no occurence at all
func consume_until(what: String, line: String) -> String:
	var idx = line.find(what)

	var result := line.left(idx)
	line = line.right(-idx)
	return result

## consumes an identifier from the line, returning "" if there is none
func consume_ident(line: String) -> String:
	var n: int = 1
	while n <= len(line) and line.left(n).is_valid_ascii_identifier():
		n += 1

	var ident := line.left(n-1)
	line = line.right(-(n-1))

	return ident

## consumes an ident from the string, adding a token and reutnring false if there was no ident
func add_ident(line: String) -> bool:
	var ident := consume_ident(line)
	if ident:
		tokens.append(Token.new(TokenType.IDENT, ident))
		return true
	return false

## Tries to consume a heading (ident preceeding a colon). REturns the ident
func consume_heading(line: String) -> String:
	var n: int = 1
	while n <= len(line) and line.left(n).is_valid_ascii_identifier():
		n += 1

	if not line.right(-(n-1)).begins_with(":"): return ""

	var ident := line.left(n-1)
	line = line.right(-(n-1))
	return ident

## when you are finished parsing the line. Consumes comments, throws error otherwise
func expect_eol(line: String) -> void:
	line = line.strip_edges()
	if not line.begins_with("#"):
		push_error("TODO ERROR SYSTEM")
	
	line = ""
	