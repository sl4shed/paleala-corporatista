extends Control

func _ready() -> void:
	Net.player_message.connect(_on_player_message)

func _on_player_message(id: String, data: Variant) -> void:
	if not Game.players.has(id) or typeof(data) != TYPE_DICTIONARY:
		return
	if Game.get_player_value(id, "host") and data.get("skip") == true:
		Game.goto_screen("drawing")

func animation_finished(_anim_name: StringName = &"") -> void:
	Game.goto_screen("drawing")
