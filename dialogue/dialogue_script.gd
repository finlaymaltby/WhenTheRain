extends Node

const ID_END: int = -1
const AUTO_WAIT_TIME: float = 1

func is_ident(s: String) -> bool:
	return s.is_valid_ascii_identifier()

func ident_head(ident: String) -> String:
	return ident.split(".")[0]

func ident_last(ident: String) -> String:
	return ident.split(".")[-1]

## a.b.c.d -> b:c:d
func get_property_path(ident: String) -> String:
	var path := ident.replace(".", ":")
	var node_path := path as NodePath
	return node_path.get_concatenated_subnames()

func _ready() -> void:
	var body := CombatBody.new()
	var p3e := PEvent.new(PEvent.State.new(body, null))
	p3e.get_indexed(":state:body")
	
	var expr := Expression.new()
	expr.parse("pe.state.body", ["pe"])
	expr.execute([p3e])
	
