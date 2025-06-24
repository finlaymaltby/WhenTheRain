class_name DResource extends Resource

## Uncompiled dialogue lines
var lines: Array[DLine]

## List of required globals
var _global_imports: Dictionary[Script, String]

## List of required scripts with a qualifier name. An instance of each must be given. 
var _required_scripts: Dictionary[Script, String]

## String name of the variable to the script 
var _script_map: Dictionary[String, Script]
## map of used names to the name of the script they are accessed from
var _using_map: Dictionary[String, String]

var headings: Dictionary[String, int]
var labels: Dictionary[String, int]


static func empty() -> DResource:
	var res = DResource.new()
	return res

func _init() -> void:
	lines = []
	_global_imports = {}
	_required_scripts = {}
	_script_map = {}

	headings = {}
	labels = {}

## Returns an error message
func add_global(global: Script, name: String) -> String:
	_global_imports[global] = name
	return ""

## Returns an error message
func add_require(script: Script, alias: String) -> String:
	if _required_scripts.has(script):
		if _required_scripts.get(script) == alias:
			return "You must qualify names when requiring more than one instance of the same type"
	_required_scripts[script] = alias
	return ""

func add_script(name: String, script: Script) -> void:
	if _script_map.has(name):
		if _script_map.get(name) != script:
			push_error("internal parser error has occured")
	_script_map[name] = script

## returns an error
func add_use(var_name: String, script_name: String) -> String:
	if _using_map.has(var_name) and _using_map.get(var_name) != script_name:
		return "Name collision of '" + var_name + "' in " + script_name + " and " + _using_map.get(var_name)
	_using_map[var_name] = script_name
	return ""
