extends Control

func play() -> void:
	get_tree().change_scene_to_file("res://scenes/lobby.tscn")

func options() -> void:
	pass # todo add volume settings and thas kinda it

func quit() -> void:
	get_tree().quit()
	
