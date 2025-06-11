extends LocalStory

func demo_fight() -> void:
	print("time to fight")
	get_tree().change_scene_to_file("res://Scenes/Fights/side_on.tscn")
