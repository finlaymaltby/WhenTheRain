class_name DialogueResource extends Resource

## Uncompiled dialogue lines
var lines: Array[DialogueLine]

## List of required globals and their corresponding alias
var _global_imports: Dictionary[Script, String]

## List of required scripts with an alias. An instance of each must be given. 
var _required_objects: Dictionary[Script, String]

## The set of aliases of all imports and requires
var aliases: Array[String]

## Script of the object that has had its symbols brought into scope
var _open_object: Script

var titles: Dictionary[String, int]

static func empty() -> DialogueResource:
	var res = DialogueResource.new()
	return res

func _init() -> void:
	lines = []
	_global_imports = {}
	_required_objects = {}

	titles = {"END": Dialogue.ID_END}

func add_global(global: Script, alias: String) -> void:
	_global_imports[global] = alias
	aliases.append(alias)

## Returns an error message
func add_require(script: Script, alias: String) -> void:
	_required_objects[script] = alias
	aliases.append(alias)

## returns an error
func add_require_using(script: Script) -> String:
	if _open_object and _open_object != script:
		return "Cannot 'require using' two different objects in the same file"
	add_require(script, "")
	return ""
	
func display_debug() -> void:
	print(_global_imports)
	print(_required_objects)

	print(titles)
	for line in lines:
		print(line)
