class_name Compiler extends Node

var res: DResource
var global_map

func _init(_resource: DResource) -> void:
	res = _resource

func compile(requires: Array[Object]) -> Dialogue:
	var tree := Engine.get_main_loop() as SceneTree
	var root := tree.root


	for global in res._global_imports:
		for child in root.get_children():
			if is_instance_of(child, global):
				print("yay")

	breakpoint
	return null
