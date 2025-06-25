extends Node

const ID_END: int = -1
const AUTO_WAIT_TIME: float = 1

func is_ident(s: String) -> bool:
	return s.is_valid_ascii_identifier()

func ident_head(ident: String) -> String:
	return ident.split(".")[0]

func ident_last(ident: String) -> String:
	return ident.split(".")[-1]

func expr_to_string(expr: Expression) -> String:
	return "EXPR"
