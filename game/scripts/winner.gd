extends Control

func _ready() -> void:
	var upgrade: Dictionary = Game.winner.get("upgrade", {})
	if upgrade.is_empty():
		$TextureRect/Banner/Label.text = "Nobody won. The investors are furious."
		$TextureRect/Image.visible = false
		$TextureRect/Title.visible = false
		$TextureRect/Credits.visible = false
	else:
		$TextureRect/Image.texture = upgrade.texture
		$TextureRect/Title/Label.text = upgrade.detail.title
		var lines := []
		var author := Game.problem_author(upgrade)
		if author != "":
			lines.append("Problem by %s" % _name(author))
		lines.append("Invented by %s" % _name(upgrade.get("owner", "")))
		lines.append("Upgraded by %s" % _name(upgrade.player))
		$TextureRect/Credits/Label.text = "\n".join(lines)

	Game.show_on_phones({
		"screen": "winner",
		"winner": upgrade.get("detail", {}).get("title", ""),
		"lines": Game.winner.get("lines", []),
	})
	_celebrate()

func _name(id: String) -> String:
	return Game.players[id].name if Game.players.has(id) else "someone who left"

func _celebrate() -> void:
	_pop($TextureRect/Banner)
	for sound in ["TaDa", "Crowd"]:
		if has_node(sound):
			get_node(sound).play()
	await get_tree().create_timer(1.0).timeout
	for node in [$TextureRect/Image, $TextureRect/Title, $TextureRect/Credits]:
		if node.visible:
			_pop(node)
			await get_tree().create_timer(0.4).timeout
	await get_tree().create_timer(2.0).timeout
	for sound in ["Outro1", "Outro2"]:
		if has_node(sound):
			get_node(sound).play()
			await get_node(sound).finished
	await get_tree().create_timer(2.0).timeout
	_back_to_menu()

func _back_to_menu() -> void:
	Net.close()
	Game.reset()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _pop(node: Control) -> void:
	node.pivot_offset = node.size / 2
	node.scale = Vector2.ZERO
	create_tween().tween_property(node, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
