extends Control

const NEXT_SCREEN := "2.0_drawing"

var assigned := {}
var finished := false
@onready var submitted_list: HBoxContainer = $TextureRect/HBoxContainer
@onready var submitted_template: Control = $TextureRect/HBoxContainer/Panel

func _ready() -> void:
	submitted_list.remove_child(submitted_template)
	Game.players_changed.connect(_redraw)
	Net.player_message.connect(_on_player_message)
	_redraw()
	_assign()
	$"TextureRect/Time Left".max_value = $Timer.wait_time
	$Timer.start()

# nobody upgrades a product they made or that solves their own problem
func _assign() -> void:
	Game.upgrades.clear()
	var dealt = Game.deal(Game.images, Game.player_ids(), func(id, e): return e.player == id or Game.problem_author(e) == id)
	for upgrader in dealt:
		var original = dealt[upgrader]
		assigned[upgrader] = original
		Net.send_to(upgrader, {
			"type": "upgrade",
			"title": original.detail.title,
			"description": original.detail.description,
			"reviews": original.get("reviews", []).map(func(r): return r.text),
			"image": Marshalls.raw_to_base64(original.image.save_png_to_buffer()),
		})

func _process(_delta: float) -> void:
	$"TextureRect/Time Left".value = $Timer.time_left

func timeout() -> void:
	$Timer.stop()
	for id in _missing():
		Net.send_to(id, {"type": "upgrade_force_submit"})

	await get_tree().create_timer(3.0).timeout
	if finished:
		return
	for id in _missing():
		_add(id, "", true)
	_finish(false)

func _on_player_message(id: String, data: Variant) -> void:
	if not Game.players.has(id) or typeof(data) != TYPE_DICTIONARY: return
	if data.get("type") != "upgrade" and data.get("type") != "upgrade_force_submit": return
	if not assigned.has(id) or not id in _missing(): return

	var forced = data.get("type") == "upgrade_force_submit"
	var description = str(data.get("description", "")).strip_edges()
	if not forced and description == "": return

	_add(id, description, forced)

	if _missing().is_empty():
		_finish($Timer.time_left > 5)

func _add(id: String, description: String, auto: bool) -> void:
	var original: Dictionary = assigned[id]
	Game.upgrades.append({
		"player": id,
		"owner": original.player,
		"original": original,
		"image": original.image,
		"texture": original.texture,
		"detail": {
			"title": "%s 2.0" % original.detail.title,
			"description": description if description != "" else "%s Now twice as much!" % original.detail.description,
		},
		"auto": auto or description == "",
	})
	_redraw()

func _missing() -> Array:
	var done = Game.upgrades.map(func(u): return u.player)
	return assigned.keys().filter(func(id): return not id in done)

func _finish(early: bool) -> void:
	if finished:
		return
	finished = true
	$Timer.stop()
	if has_node("AudioStreamPlayer"):
		$AudioStreamPlayer.stop()
	var sound = "AudioStreamPlayer3" if early else "AudioStreamPlayer2"
	if has_node(sound):
		get_node(sound).play()
		await get_node(sound).finished
	Game.goto_screen(NEXT_SCREEN)

func _redraw() -> void:
	for child in submitted_list.get_children():
		child.queue_free()
	for entry in Game.upgrades:
		if entry.get("auto", false) or not Game.players.has(entry.player):
			continue
		var panel := submitted_template.duplicate()
		panel.get_node("Label").text = Game.initials(Game.players[entry.player].name)
		submitted_list.add_child(panel)

func _exit_tree() -> void:
	submitted_template.queue_free()
