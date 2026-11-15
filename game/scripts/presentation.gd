extends Control

const PARTS := ["title", "description", "image"]

var next_screen := "review_tutorial"
var banner := "%s is presenting!"

var order := []
var index := -1
var shown := {}
var finishing := false

@onready var presenter_label: Label = $TextureRect/Presenter/Label
@onready var parts := {
	"title": $TextureRect/Title,
	"description": $TextureRect/Description,
	"image": $TextureRect/Image,
}

func _ready() -> void:
	Net.player_message.connect(_on_player_message)
	Game.player_reconnected.connect(_on_player_reconnected)
	order = _entries().filter(func(e): return Game.players.has(_presenter(e)))
	order.shuffle()
	_next()

func _entries() -> Array:
	return Game.images

func _process(_delta: float) -> void:
	$"TextureRect/Time Left".value = $Timer.time_left

func _current() -> Dictionary:
	return order[index] if index >= 0 and index < order.size() else {}

func _next() -> void:
	index += 1
	shown = {}
	for node in parts.values():
		node.visible = false

	var entry := _current()
	if entry.is_empty():
		Game.goto_screen(next_screen)
		return

	var detail: Dictionary = entry.detail
	$TextureRect/Title/Label.text = detail.title
	$TextureRect/Description/Label.text = detail.description
	$TextureRect/Image.texture = entry.texture
	presenter_label.text = banner % Game.players[_presenter(entry)].name
	var problem := _problem_text(entry)
	if problem != "":
		presenter_label.text += "\n\"%s\"" % problem
	_pop($TextureRect/Presenter)

	$"TextureRect/Time Left".max_value = $Timer.wait_time
	$Timer.start()
	finishing = false
	_send_all()

func _send_all() -> void:
	for id in Game.players:
		_send(id)

func _send(id: String) -> void:
	var entry := _current()
	if entry.is_empty():
		return
	if id == _presenter(entry):
		Net.send_to(id, {
			"type": "presentation",
			"presenting": true,
			"problem": _problem_text(entry),
			"title": entry.detail.title,
			"description": entry.detail.description,
			"shown": shown.keys(),
		})
	else:
		Net.send_to(id, {
			"type": "presentation",
			"presenting": false,
			"presenter": Game.players[_presenter(entry)].name,
		})

func _on_player_reconnected(id: String) -> void:
	_send(id)

func _on_player_message(id: String, data: Variant) -> void:
	if typeof(data) != TYPE_DICTIONARY or _current().is_empty() or _presenter(_current()) != id:
		return
	match data.get("type"):
		"present_show":
			_show(str(data.get("part", "")))
		"present_done":
			_finish()

func _show(part: String) -> void:
	if not parts.has(part) or shown.has(part):
		return
	shown[part] = true
	parts[part].visible = true
	_pop(parts[part])
	_send(_presenter(_current()))

func timeout() -> void:
	var was := index
	for part in PARTS:
		_show(part)
	await get_tree().create_timer(4.0).timeout
	if index == was:
		_finish()

func _finish() -> void:
	if finishing:
		return
	finishing = true
	$Timer.stop()
	if has_node("AudioStreamPlayer2"):
		$AudioStreamPlayer2.play()
	await get_tree().create_timer(1.5).timeout
	_next()

func _pop(node: Control) -> void:
	node.pivot_offset = node.size / 2
	node.scale = Vector2.ZERO
	create_tween().tween_property(node, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _presenter(entry: Dictionary) -> String:
	var author := Game.problem_author(entry)
	return author if author != "" else entry.player

func _problem_text(entry: Dictionary) -> String:
	var source: Dictionary = entry.get("original", entry)
	var problem = source.get("detail", {}).get("problem", {})
	return str(problem.get("text", "")) if typeof(problem) == TYPE_DICTIONARY else ""
