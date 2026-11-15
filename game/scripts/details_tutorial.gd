extends Control

func _ready() -> void:
	Game.player_joined.connect(_on_player_joined)
	Net.disconnected.connect(_on_disconnected)
	Net.player_message.connect(_on_player_message)

func _exit_tree() -> void:
	pass

func _on_disconnected() -> void:
	pass

func _on_player_joined(id: String) -> void:
	pass

func _on_player_message(id: String, data: Variant) -> void:
	if not Game.players.has(id) or typeof(data) != TYPE_DICTIONARY:
		return
	if Game.get_player_value(id, "host") and data.get("skip") == true:
		Game.goto_screen("details")


func animation_finished(anim_name: StringName) -> void:
	Game.goto_screen("details")
