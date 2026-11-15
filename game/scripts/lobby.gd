extends Control
@onready var code_label: Label = $"Panel/Panel/Room Code"
@onready var list: VBoxContainer = $Panel/Players
@onready var row_template: Control = $Panel/Players/Panel

func _ready() -> void:
	list.remove_child(row_template)
	Game.players_changed.connect(_redraw)
	Game.player_joined.connect(_on_player_joined)
	Net.room_created.connect(_on_room_created)
	Net.disconnected.connect(_on_disconnected)
	Net.player_message.connect(_on_player_message)

	if Net.is_open() and Net.room_code != "":
		_on_room_created(Net.room_code)
	else:
		code_label.text = "...."
		Net.host()
	_redraw()

func _exit_tree() -> void:
	row_template.queue_free()

func _on_room_created(code: String) -> void:
	code_label.text = code
	Game.show_on_phones({
		"type": "screen",
		"screen": "lobby",
		"text": "You're in! Waiting for the game to start."
	})

func _on_disconnected() -> void:
	code_label.text = "Hold Up..."

func _on_player_joined(id: String) -> void:
	if not Game.players.values().any(func(p): return p.get("host", false)):
		Game.set_player_value(id, "host", true)
		Net.send_to(id, {"host": true})

func _on_player_message(id: String, data: Variant) -> void:
	if not Game.players.has(id) or typeof(data) != TYPE_DICTIONARY:
		return
	if Game.get_player_value(id, "host") and data.get("start") == true:
		Game.goto_screen("opening")

func _redraw() -> void:
	for child in list.get_children():
		child.queue_free()
	var i := 1
	for id in Game.players:
		var p = Game.players[id]
		var row := row_template.duplicate()
		
		var text := "%d. %s" % [i, p.name]
		if p.get("host", false):
			text += " (VIP)"
		if not p.connected:
			text += " (offline)"
		
		row.get_node("Label").text = text
		row.modulate.a = 1.0 if p.connected else 0.5
		list.add_child(row)
		i += 1

func back() -> void:
	Net.close()
	Game.reset()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
