extends Control

const NEXT_SCREEN := "2.0_details_tutorial"

var fallback_reviews = [
	"One star. It arrived broken and then it broke again.",
	"My kids hate it. My dog hates it. I hate it.",
	"Did not fix my problem. Created three new ones.",
	"Smells weird. Would not recommend.",
	"I want my money back and also my dignity.",
	"Worst purchase since my timeshare.",
	"It made a noise at 3am and I haven't slept since.",
	"Customer support just laughed at me.",
]

var assigned := {}
var submitted := {}
var finished := false
@onready var submitted_list: HBoxContainer = $TextureRect/HBoxContainer
@onready var submitted_template: Control = $TextureRect/HBoxContainer/Panel

func _ready() -> void:
	submitted_list.remove_child(submitted_template)
	Net.player_message.connect(_on_player_message)
	Game.player_reconnected.connect(_send)

	$TextureRect/Panel/Label.text = "The audience is writing reviews!"

	for entry in Game.images:
		entry.reviews = []
	for id in Game.judges():
		var products := []
		for i in Game.images.size():
			var e = Game.images[i]
			if e.player != id and Game.problem_author(e) != id:
				products.append(i)
		if not products.is_empty():
			assigned[id] = products
			_send(id)
	_redraw()
	if assigned.is_empty():
		_finish.call_deferred(false)
		return
	$"TextureRect/Time Left".max_value = $Timer.wait_time
	$Timer.start()

func _process(_delta: float) -> void:
	$"TextureRect/Time Left".value = $Timer.time_left

func _send(id: String) -> void:
	if not assigned.has(id) or submitted.has(id):
		return
	Net.send_to(id, {
		"type": "review",
		"products": assigned[id].map(func(i): return {
			"index": i,
			"title": Game.images[i].detail.title,
			"description": Game.images[i].detail.description,
			"image": Marshalls.raw_to_base64(Game.images[i].image.save_png_to_buffer()),
		}),
	})

func timeout() -> void:
	$Timer.stop()
	for id in _missing():
		Net.send_to(id, {"type": "review_force_submit"})
	await get_tree().create_timer(3.0).timeout
	_finish(false)

func _on_player_message(id: String, data: Variant) -> void:
	if not Game.players.has(id) or typeof(data) != TYPE_DICTIONARY: return
	if data.get("type") != "review" and data.get("type") != "review_force_submit": return
	if not assigned.has(id) or submitted.has(id): return

	var reviews = data.get("reviews", {})
	if typeof(reviews) != TYPE_DICTIONARY: return
	for key in reviews:
		var i := int(key)
		var text := str(reviews[key]).strip_edges()
		if text != "" and i in assigned[id]:
			Game.images[i].reviews.append({"by": id, "text": text})
	submitted[id] = true
	_redraw()

	if _missing().is_empty():
		_finish($Timer.time_left > 5)

func _missing() -> Array:
	return assigned.keys().filter(func(id): return not submitted.has(id))

func _finish(early: bool) -> void:
	if finished:
		return
	finished = true
	$Timer.stop()
	var pool = fallback_reviews.duplicate()
	pool.shuffle()
	for entry in Game.images:
		if entry.reviews.is_empty():
			entry.reviews.append({"by": "", "text": pool.pop_back() if not pool.is_empty() else "Bad.", "auto": true})
	if has_node("AudioStreamPlayer"):
		$AudioStreamPlayer.stop()
	var sound = "AudioStreamPlayer3" if early else "AudioStreamPlayer2"
	if has_node(sound):
		get_node(sound).play()
		await get_node(sound).finished
	Game.goto_screen(NEXT_SCREEN)

# the whole audience shows up as one "AU" slot
func _redraw() -> void:
	for child in submitted_list.get_children():
		child.queue_free()
	var audience_done := false
	for id in submitted:
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
