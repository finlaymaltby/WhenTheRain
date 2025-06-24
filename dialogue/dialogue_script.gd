extends Node

func is_ident(s: String) -> bool:
	return s.is_valid_ascii_identifier()

func ident_head(ident: String) -> String:
	return ident.split(".")[0]

func _ready() -> void:
	var file := FileAccess.open("res://dialogue/example.txt", FileAccess.READ)
	var content := file.get_as_text(true)

	var lexer := Lexer.new(content)
	lexer.tokenise()
	print("LEXER")
	lexer.display_debug()
	print()
	print()
	print("PARSER")
	var parser := Parser.new(lexer.tokens)
	var res := parser.parse()
	parser.display_debug()
	print()
	print()

	var compiler := Compiler.new(res)
	compiler.add_named_input("db", DialogueBalloon.new())
	compiler.add_input(CombatDemoAngryGuy.new())
	compiler.add_input(null)
	compiler.compile()
	
