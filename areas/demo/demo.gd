class_name Demo extends LocalStory

var local_var := 0:
	set(value):
		breakpoint


func demo_fight() -> void:
	get_tree().change_scene_to_file("res://fights/demo_fight/demo_fight.tscn")
