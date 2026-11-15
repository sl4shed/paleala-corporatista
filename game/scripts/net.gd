extends Node
## Usage:
##   Net.room_created.connect(func(code): ...)
##   Net.host()
##   Net.broadcast({screen = "prompt", text = "Say something"})
##   Net.send_to(player_id, {screen = "wait"})

signal room_created(code: String)
signal player_joined(id: String, player_name: String, rejoin: bool)
signal player_left(id: String)
signal player_message(id: String, data: Variant)
signal disconnected()
@export var server_url := "ws://localhost:3000/ws"

var room_code := ""
var _ws := WebSocketPeer.new()
var _was_open := false

func host() -> void:
	room_code = ""
	_was_open = false
	_ws = WebSocketPeer.new()
	_ws.inbound_buffer_size = 1 << 22 # drawings are big
	var err := _ws.connect_to_url(server_url + "?role=host")
	if err != OK:
		push_error("Net: could not connect to %s (%s)" % [server_url, error_string(err)])


func is_open() -> bool:
	return _ws.get_ready_state() == WebSocketPeer.STATE_OPEN


func send_to(id: String, data: Variant) -> void:
	if is_open():
		_ws.send_text(JSON.stringify({"to": id, "data": data}))


func broadcast(data: Variant) -> void:
	send_to("all", data)


func close() -> void:
	_ws.close()


func _process(_delta: float) -> void:
	_ws.poll()
	var state := _ws.get_ready_state()

	if state == WebSocketPeer.STATE_OPEN:
		_was_open = true
		while _ws.get_available_packet_count() > 0:
			_handle(_ws.get_packet().get_string_from_utf8())
	elif state == WebSocketPeer.STATE_CLOSED and _was_open:
		_was_open = false
		room_code = ""
		disconnected.emit()


func _handle(text: String) -> void:
	var m = JSON.parse_string(text)
	if typeof(m) != TYPE_DICTIONARY:
		return
	match m.get("type"):
		"room":
			room_code = m["code"]
			room_created.emit(room_code)
		"join":
			player_joined.emit(m["id"], m["name"], m.get("rejoin", false))
		"leave":
			player_left.emit(m["id"])
		"msg":
			player_message.emit(m["from"], m.get("data"))
