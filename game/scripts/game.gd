extends Node
signal players_changed()
signal player_joined(id: String)
signal player_reconnected(id: String)
signal player_disconnected(id: String)
signal player_removed(id: String)
signal player_updated(id: String, key: String, value: Variant)

var problems := []
var details := []
var images := []
var players := {}:
	set(value):
		players = value
		players_changed.emit()

var current_screen := {"screen": "wait", "text": "Waiting to start the game..."}
func _ready() -> void:
	Net.player_joined.connect(_on_join)
	Net.player_left.connect(_on_leave)

func _on_join(id: String, player_name: String, _rejoin: bool) -> void:
	if players.has(id):
		players[id].connected = true
		if players[id].name != player_name:
			players[id].name = player_name
			player_updated.emit(id, "name", player_name)
		player_reconnected.emit(id)
	else:
		players[id] = {"name": player_name, "connected": true, "score": 0, "host": false, "audience": false}
		player_joined.emit(id)
	Net.send_to(id, current_screen)
	
	if players[id].get("host", false): Net.send_to(id, {"host": true})
	if players[id].get("audience", false): Net.send_to(id, {"audience": true})
		
	players_changed.emit()

func _on_leave(id: String) -> void:
	if not players.has(id):
		return
	players[id].connected = false
	player_disconnected.emit(id)
	players_changed.emit()

func set_player_value(id: String, key: String, value: Variant) -> void:
	if not players.has(id):
		return
	players[id][key] = value
	player_updated.emit(id, key, value)
	players_changed.emit()

func get_player_value(id: String, key: String) -> Variant:
	if not players.has(id):
		return
	return players[id][key]

func add_score(id: String, amount: int) -> void:
	if players.has(id):
		set_player_value(id, "score", players[id].score + amount)

func reset() -> void:
	var old := players.keys()
	players = {}
	for id in old:
		player_removed.emit(id)
	current_screen = {"screen": "wait", "text": "Waiting to start the game..."}

func show_on_phones(screen: Dictionary) -> void:
	current_screen = screen
	Net.broadcast(screen)
	
func connected_ids() -> Array:
	return players.keys().filter(func(id): return players[id].connected)

func goto_screen(scene: String) -> void:
	get_tree().change_scene_to_file("res://scenes/%s.tscn" % scene)
	Net.broadcast({ "screen": scene })
	current_screen = { "screen": scene }
	
