extends Node
signal players_changed()
signal player_joined(id: String)
signal player_reconnected(id: String)
signal player_disconnected(id: String)
signal player_removed(id: String)
signal player_updated(id: String, key: String, value: Variant)

const MAX_PLAYERS := 4

var problems := []
var details := []
var images := []
var upgrades := []
var votes := {}
var winner := {}
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
		var in_game = not current_screen.get("screen") in ["wait", "lobby"]
		var audience = in_game or player_ids().size() >= MAX_PLAYERS
		players[id] = {"name": player_name, "connected": true, "score": 0, "host": false, "audience": audience}
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
	for list in [problems, details, images, upgrades]:
		list.clear()
	votes.clear()
	winner = {}

func show_on_phones(screen: Dictionary) -> void:
	current_screen = screen
	Net.broadcast(screen)
	
func initials(player_name: String) -> String:
	var words = player_name.strip_edges().split(" ", false)
	if words.is_empty():
		return "?"
	if words.size() == 1:
		return words[0].left(2).to_upper()
	return (words[0].left(1) + words[1].left(1)).to_upper()

func connected_ids() -> Array:
	return players.keys().filter(func(id): return players[id].connected)

func player_ids() -> Array:
	return players.keys().filter(func(id): return not players[id].get("audience", false))

func audience_ids() -> Array:
	return players.keys().filter(func(id): return players[id].get("audience", false))

# only the audience writes reviews and votes
func judges() -> Array:
	return audience_ids().filter(func(id): return players[id].connected)

# random taker -> item pairing where forbidden.call(taker, item) is false when possible
func deal(items: Array, takers: Array, forbidden: Callable) -> Dictionary:
	var best := {}
	var best_bad := INF
	for attempt in 500:
		var pool = items.duplicate()
		pool.shuffle()
		var result := {}
		var bad := 0
		for i in min(takers.size(), pool.size()):
			result[takers[i]] = pool[i]
			if forbidden.call(takers[i], pool[i]):
				bad += 1
		if bad < best_bad:
			best = result
			best_bad = bad
		if bad == 0:
			break
	return best

# who made the problem this product solves; they present it
func problem_author(entry: Dictionary) -> String:
	if entry.has("original"):
		entry = entry.original
	var problem = entry.get("detail", {}).get("problem", {})
	var author = problem.get("player", "") if typeof(problem) == TYPE_DICTIONARY else ""
	return author if players.has(author) else ""

func goto_screen(scene: String) -> void:
	get_tree().change_scene_to_file("res://scenes/%s.tscn" % scene)
	Net.broadcast({ "screen": scene })
	current_screen = { "screen": scene }
	
