extends Control

var assigned := {}
var finished := false
@onready var submitted_list: HBoxContainer = $TextureRect/HBoxContainer
@onready var submitted_template: Control = $TextureRect/HBoxContainer/Panel

func _ready() -> void:
	submitted_list.remove_child(submitted_template)
	Net.player_message.connect(_on_player_message)
	Game.player_reconnected.connect(_send)
	Game.votes.clear()
	$TextureRect/Results.visible = false

	var audience_judging = not Game.audience_ids().is_empty()
	$TextureRect/Panel/Label.text = "The audience is voting for the best product!" if audience_judging else "Vote for the best product on your phone!"

	for id in Game.judges():
		var options := []
		for i in Game.upgrades.size():
			if not _involved(id, Game.upgrades[i]):
				options.append(i)
		if options.is_empty():
			options = range(Game.upgrades.size())
		if not options.is_empty():
			assigned[id] = options
			_send(id)
	_redraw()
	$"TextureRect/Time Left".max_value = $Timer.wait_time
	$Timer.start()

func _involved(id: String, upgrade: Dictionary) -> bool:
	return id == upgrade.player or id == upgrade.get("owner", "") or id == Game.problem_author(upgrade)

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

func timeout() -> void:
	_finish()

func _on_player_message(id: String, data: Variant) -> void:
	if not Game.players.has(id) or typeof(data) != TYPE_DICTIONARY: return
	if finished and data.get("again") == true and Game.get_player_value(id, "host"):
		Game.goto_screen("lobby")
		return
	if data.get("type") != "vote" or not assigned.has(id) or Game.votes.has(id): return
	var i := int(data.get("index", -1))
	if not i in assigned[id]: return
	Game.votes[id] = i
	_redraw()
	if Game.votes.size() == assigned.size():
		_finish()

func _tally() -> Array:
	var rows := []
	for i in Game.upgrades.size():
		var u = Game.upgrades[i]
		var count = Game.votes.values().count(i)
		rows.append({"index": i, "title": u.detail.title, "votes": count, "upgrade": u})
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
	$TextureRect/Panel.visible = false
	submitted_list.visible = false

	var rows = _tally()
	var lines := []
	for row in rows:
		lines.append("%s - %d vote%s" % [row.title, row.votes, "" if row.votes == 1 else "s"])
	var text := "No products?!"
	if not rows.is_empty():
		var top = rows[0].upgrade
		for id in [top.player, top.get("owner", "")]:
			if Game.players.has(id):
				Game.add_score(id, 1)
		text = "Best product: %s!\nInvented by %s, upgraded by %s\n\n%s" % [rows[0].title, _name(top.get("owner", "")), _name(top.player), "\n".join(lines)]
	$TextureRect/Results/Label.text = text
	$TextureRect/Results.visible = true
	if has_node("AudioStreamPlayer"):
		$AudioStreamPlayer.stop()
	if has_node("AudioStreamPlayer3"):
		$AudioStreamPlayer3.play()

	Game.show_on_phones({"screen": "results", "winner": rows[0].title if not rows.is_empty() else "", "lines": lines})

# the whole audience shows up as one "AU" slot
func _redraw() -> void:
	for child in submitted_list.get_children():
		child.queue_free()
	var audience_done := false
	for id in Game.votes:
		if not Game.players.has(id):
			continue
		if Game.players[id].get("audience", false):
			audience_done = true
			continue
		_add_panel(Game.initials(Game.players[id].name))
	if audience_done:
		_add_panel("AU")

func _add_panel(text: String) -> void:
	var panel := submitted_template.duplicate()
	panel.get_node("Label").text = text
	submitted_list.add_child(panel)

func _exit_tree() -> void:
	submitted_template.queue_free()
