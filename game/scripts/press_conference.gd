extends "res://scripts/presentation.gd"

func _init() -> void:
	next_screen = "vote"
	banner = "%s is holding a press conference!"

func _entries() -> Array:
	return Game.upgrades
