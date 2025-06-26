class_name DialogueResource extends Resource

## Uncompiled dialogue lines
var lines: Array[DialogueLine]

## List of required globals
var _global_imports: Dictionary[Script, String]

## List of required scripts with an alias. An instance of each must be given. 
var _required_objects: Dictionary[Script, String]

## String name of the object name to the script it must inherit from
var _script_map: Dictionary[String, Script]

## script of the using object
var _using_object: Script

var labels: Dictionary[String, int]

static func empty() -> DialogueResource:
	var res = DialogueResource.new()
	return res

func _init() -> void:

	lines = []
	_global_imports = {}
	_required_objects = {}
	_script_map = {}

	labels = {"END": Dialogue.ID_END}

## Returns an error message
func add_global(global: Script, name: String) -> String:
	_global_imports[global] = name
	add_script(name, global)
	return ""

## Returns an error message
func add_require(script: Script, alias: String) -> String:
	if _required_objects.has(script):
		if _required_objects.get(script) == alias:
			return "You must qualify names when requiring more than one instance of the same type"
	_required_objects[script] = alias
	add_script(alias, script)
	return ""

func add_script(name: String, script: Script) -> void:
	if _script_map.has(name):
		if _script_map.get(name) != script:
			push_error("internal parser error has occured")
	_script_map[name] = script

## returns an error
func add_require_using(script: Script) -> String:
	if _using_object and _using_object != script:
		return "Cannot 'require using' two different objects in the same file"

	return add_require(script, "")
	
func display_debug() -> void:
	print(_global_imports)
	print(_required_objects)

	print(labels)
	for line in lines:
		print(line)
