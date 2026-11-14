extends Control
func _ready() -> void:
	Game.players_changed.connect(_redraw)
	Game.player_joined.connect(_on_player_joined)
	Net.disconnected.connect(_on_disconnected)
	Net.player_message.connect(_on_player_message)
	_redraw()

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
		Game.goto_screen("problems_tutorial")

func _connected_count() -> int:
	return Game.connected_ids().size()

func _redraw() -> void:
	pass
