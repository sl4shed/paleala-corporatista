extends Control

var buzzwords = [
	"blockchain",
	"NFT",
	"crypto",
	"5G",
	"microwave",
	"AI",
	"Machine Learning",
	"Transformer",
	"IT",
	"Collider",
	"Superpositioned",
	"Quantum",
	"AI Partner",
	"AI Girlfriend",
	"AI Boyfriend",
	"My Little Pony",
	"Protein",
	"Antenna",
	"Silicon",
	"Silicon Valley",
]

var assigned := {}
var finished := false

func _ready() -> void:
	Game.players_changed.connect(_redraw)
	Net.player_message.connect(_on_player_message)
	Game.details.clear()
	_redraw()

	var problems2 = Game.problems.duplicate()
	for id in Game.players:
		var words = buzzwords.duplicate()
		words.shuffle()
		words = words.slice(0, 3)
		var problem = problems2.pick_random()
		problems2.remove_at(problems2.find(problem))
		
		assigned[id] = {
			"buzzwords": words,
			"problem": problem
		}
		Net.send_to(id, {
			"type": "details",
			"buzzwords": words,
			"problem": problem
		})
	$Timer.start()

func timeout() -> void:
	$Timer.stop()
	for id in _missing():
		Net.send_to(id, {
			"type": "details_force_submit"
		})

	await get_tree().create_timer(3.0).timeout
	if finished:
		return
	for id in _missing():
		_add(id, "", "", true)
	_finish(false)

func _on_player_message(id: String, data: Variant) -> void:
	if not Game.players.has(id) or typeof(data) != TYPE_DICTIONARY: return
	if data.get("type") != "details" and data.get("type") != "details_force_submit": return
	if not assigned.has(id) or not id in _missing(): return

	var forced = data.get("type") == "details_force_submit"
	var title = str(data.get("title", "")).strip_edges()
	var description = str(data.get("description", "")).strip_edges()
	if not forced and (title == "" or description == ""): return

	_add(id, title, description, forced)

	if _missing().is_empty():
		_finish($Timer.time_left > 5)

func _add(id: String, title: String, description: String, auto: bool) -> void:
	var words: Array = assigned[id].buzzwords
	Game.details.append({
		"player": id,
		"title": title if title != "" else "The %s %s" % [words[0], words[1]],
		"description": description if description != "" else "It's %s, but with %s." % [", ".join(words.slice(0, -1)), words[-1]],
		"buzzwords": words,
		"problem": assigned[id].problem,
		"auto": auto or title == "" or description == ""
	})

func _missing() -> Array:
	var answered = Game.details.map(func(d): return d.player)
	return assigned.keys().filter(func(id): return not id in answered)

func _finish(early: bool) -> void:
	if finished:
		return
	finished = true
	$Timer.stop()
	if has_node("AudioStreamPlayer"):
		$AudioStreamPlayer.stop()
	var sound = "AudioStreamPlayer3" if early else "AudioStreamPlayer2" # finished early / moving on
	if has_node(sound):
		get_node(sound).play()
		await get_node(sound).finished
	Game.goto_screen("drawing_tutorial")

func _redraw() -> void:
	pass
