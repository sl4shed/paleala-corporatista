extends Control

var assigned := {}
var finished := false
var cards := []
@onready var banner: Label = $TextureRect/Banner/Label
@onready var product_list: HBoxContainer = $TextureRect/Products
@onready var card_template: Control = $TextureRect/Products/Card

func _ready() -> void:
	product_list.remove_child(card_template)
	Net.player_message.connect(_on_player_message)
	Game.player_reconnected.connect(_send)
	Game.votes.clear()

	for u in Game.upgrades:
		var card := card_template.duplicate()
		card.get_node("Image").texture = u.texture
		card.get_node("Title").text = u.detail.title
		product_list.add_child(card)
		cards.append(card)

	for id in Game.judges():
		assigned[id] = range(Game.upgrades.size())
		_send(id)
	_update_banner()

	if assigned.is_empty() or Game.upgrades.is_empty():
		_finish.call_deferred()
		return
	$"TextureRect/Time Left".max_value = $Timer.wait_time
	$Timer.start()

func _process(_delta: float) -> void:
	$"TextureRect/Time Left".value = $Timer.time_left

func _send(id: String) -> void:
	if finished or not assigned.has(id) or Game.votes.has(id):
		return
	Net.send_to(id, {
		"type": "vote",
		"options": assigned[id].map(func(i): return {
			"index": i,
			"title": Game.upgrades[i].detail.title,
			"description": Game.upgrades[i].detail.description,
			"image": Marshalls.raw_to_base64(Game.upgrades[i].image.save_png_to_buffer()),
		}),
	})

func _update_banner() -> void:
	banner.text = "The audience is voting for the best product!\n%d/%d votes in" % [Game.votes.size(), assigned.size()]

func timeout() -> void:
	_finish()

func _on_player_message(id: String, data: Variant) -> void:
	if not Game.players.has(id) or typeof(data) != TYPE_DICTIONARY: return
	if finished or data.get("type") != "vote" or not assigned.has(id) or Game.votes.has(id): return
	var i := int(data.get("index", -1))
	if not i in assigned[id]: return
	Game.votes[id] = i
	if has_node("AudioStreamPlayer2"):
		$AudioStreamPlayer2.play()
	_update_banner()
	if Game.votes.size() == assigned.size():
		_finish()

func _tally() -> Array:
	var rows := []
	for i in Game.upgrades.size():
		rows.append({"index": i, "title": Game.upgrades[i].detail.title, "votes": Game.votes.values().count(i)})
	rows.sort_custom(func(a, b): return a.votes > b.votes)
	return rows

func _name(id: String) -> String:
	return Game.players[id].name if Game.players.has(id) else "?"

func _finish() -> void:
	if finished:
		return
	finished = true
	$Timer.stop()
	$"TextureRect/Time Left".visible = false
	if has_node("AudioStreamPlayer"):
		$AudioStreamPlayer.stop()

	var rows = _tally()
	var lines := []
	for row in rows:
		lines.append("%s - %d vote%s" % [row.title, row.votes, "" if row.votes == 1 else "s"])
	if rows.is_empty():
		Game.winner = {}
		Game.goto_screen("winner")
		return

	banner.text = "The votes are in..."
	for row in rows:
		var votes: Label = cards[row.index].get_node("Votes")
		votes.text = "%d vote%s" % [row.votes, "" if row.votes == 1 else "s"]
		votes.visible = true
		_pop(votes)
		await get_tree().create_timer(0.6).timeout

	var top = Game.upgrades[rows[0].index]
	for id in [top.player, top.get("owner", "")]:
		if Game.players.has(id):
			Game.add_score(id, 1)
	for i in cards.size():
		if i != rows[0].index:
			create_tween().tween_property(cards[i], "modulate:a", 0.35, 0.4)
	var winner: Control = cards[rows[0].index]
	winner.pivot_offset = winner.size / 2
	create_tween().tween_property(winner, "scale", Vector2(1.15, 1.15), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	banner.text = "Best product: %s!\nInvented by %s, upgraded by %s" % [top.detail.title, _name(top.get("owner", "")), _name(top.player)]
	_pop($TextureRect/Banner)
	if has_node("AudioStreamPlayer3"):
		$AudioStreamPlayer3.play()

	Game.show_on_phones({"screen": "results", "winner": top.detail.title, "lines": lines})
	Game.winner = {"upgrade": top, "lines": lines}
	await get_tree().create_timer(5.0).timeout
	Game.goto_screen("winner")

func _pop(node: Control) -> void:
	node.pivot_offset = node.size / 2
	node.scale = Vector2.ZERO
	create_tween().tween_property(node, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _exit_tree() -> void:
	card_template.queue_free()
