extends Control

const SIZE := 600

var assigned := {}
var finished := false
@onready var submitted_list: HBoxContainer = $TextureRect/HBoxContainer
@onready var submitted_template: Control = $TextureRect/HBoxContainer/Panel

func _ready() -> void:
	submitted_list.remove_child(submitted_template)
	Game.players_changed.connect(_redraw)
	Net.player_message.connect(_on_player_message)
	Game.player_reconnected.connect(_send)
	Game.images.clear()
	_redraw()

	$"TextureRect/Time Left".max_value = $Timer.wait_time
	for detail in Game.details:
		var id = detail.player
		if not id in Game.player_ids():
			continue
		assigned[id] = detail
		_send(id)
	$Timer.start()

func _send(id: String) -> void:
	if not assigned.has(id) or not id in _missing():
		return
	Net.send_to(id, {
		"type": "drawing",
		"title": assigned[id].title,
		"description": assigned[id].description,
	})

func _process(_delta: float) -> void:
	$"TextureRect/Time Left".value = $Timer.time_left

func timeout() -> void:
	$Timer.stop()
	for id in _missing():
		Net.send_to(id, {"type": "drawing_force_submit"})

	await get_tree().create_timer(3.0).timeout
	if finished:
		return
	for id in _missing():
		_add(id, null, true)
	_finish(false)

func _on_player_message(id: String, data: Variant) -> void:
	if not Game.players.has(id) or typeof(data) != TYPE_DICTIONARY: return
	if data.get("type") != "drawing" and data.get("type") != "drawing_force_submit": return
	if not assigned.has(id) or not id in _missing(): return

	var img := _decode(str(data.get("image", "")))
	if img == null and data.get("type") == "drawing": return

	_add(id, img, data.get("type") == "drawing_force_submit")

	if _missing().is_empty():
		_finish($Timer.time_left > 5)

func _decode(b64: String) -> Image:
	if b64 == "":
		return null
	var img := Image.new()
	if img.load_png_from_buffer(Marshalls.base64_to_raw(b64)) != OK:
		return null
	return img

func _add(id: String, img: Image, auto: bool) -> void:
	if img == null:
		img = Image.create_empty(SIZE, SIZE, false, Image.FORMAT_RGBA8)
		img.fill(Color.WHITE)
		auto = true
	Game.images.append({
		"player": id,
		"image": img,
		"texture": ImageTexture.create_from_image(img),
		"detail": assigned[id],
		"auto": auto,
	})
	_redraw()

func _missing() -> Array:
	var drawn = Game.images.map(func(d): return d.player)
	return assigned.keys().filter(func(id): return not id in drawn)

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
	Game.goto_screen("presentation_tutorial")

func _redraw() -> void:
	for child in submitted_list.get_children():
		child.queue_free()
	for entry in Game.images:
		if entry.get("auto", false) or not Game.players.has(entry.player):
			continue
		var panel := submitted_template.duplicate()
		panel.get_node("Label").text = Game.initials(Game.players[entry.player].name)
		submitted_list.add_child(panel)

func _exit_tree() -> void:
	submitted_template.queue_free()
