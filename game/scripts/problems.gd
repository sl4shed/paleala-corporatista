extends Control

var problems = [
	{
		"text": "My ___ keep exploding!",
		"blanks": 1
	},
	{
		"text": "I can't stop ___!",
		"blanks": 1
	},
	{
		"text": "I can't figure out ___!",
		"blanks": 1
	},
	{
		"text": "I ___ my ___!",
		"blanks": 2,
	}, 
	{
		"text": "I keep ___ my ___!",
		"blanks": 2
	},
	{
		"text": "My boss won't stop ___!",
		"blanks": 1
	},
	{
		"text": "There's a ___ living in my ___!",
		"blanks": 2
	},
	{
		"text": "Every time I ___, my ___ starts crying!",
		"blanks": 2
	},
	{
		"text": "I accidentally married a ___!",
		"blanks": 1
	},
	{
		"text": "My ___ is smarter than me!",
		"blanks": 1
	},
	{
		"text": "I'm allergic to ___!",
		"blanks": 1
	},
	{
		"text": "My neighbour keeps ___ at 3 AM!",
		"blanks": 1
	},
	{
		"text": "I can't stop thinking about ___!",
		"blanks": 1
	},
	{
		"text": "My ___ got stuck in my ___!",
		"blanks": 2
	},
	{
		"text": "I sold my ___ for a ___!",
		"blanks": 2
	},
	{
		"text": "I think my ___ is plotting against me!",
		"blanks": 1
	},
	{
		"text": "I lost my ___ in a bet with a ___!",
		"blanks": 2
	},
	{
		"text": "My grandma only talks about ___!",
		"blanks": 1
	},
	{
		"text": "I replaced my ___ with ___ and now nothing works!",
		"blanks": 2
	},
	{
		"text": "My ___ won't stop ___!",
		"blanks": 2
	},
	{
		"text": "I got fired for ___!",
		"blanks": 1
	},
	{
		"text": "I'm being haunted by ___!",
		"blanks": 1
	},
	{
		"text": "My ___ smells like ___!",
		"blanks": 2
	},
	{
		"text": "There are ___ in my walls!",
		"blanks": 1
	},
	{
		"text": "I can't sleep because of ___!",
		"blanks": 1
	},
	{
		"text": "I tried to ___ a ___ and it went horribly wrong!",
		"blanks": 2
	}
]

var fallback_answers = [
	"socks",
	"grandma",
	"a haunted toaster",
	"spaghetti",
	"the printer",
	"my landlord",
	"crying",
	"licking",
	"a raccoon",
	"taxes",
	"yodeling",
	"the neighbour's cat",
	"a suspicious sandwich",
	"dancing",
	"my ex",
	"forty pigeons",
	"microwaving",
	"a tiny horse",
	"the vibes",
	"cheese",
]

var assigned := {}
@onready var submitted_list: HBoxContainer = $Panel/HBoxContainer
@onready var submitted_template: Control = $Panel/HBoxContainer/Panel

var rng = RandomNumberGenerator.new()
func _process(delta):
	$"Panel/Time Left".value = $Timer.time_left

func _ready() -> void:
	submitted_list.remove_child(submitted_template)
	Game.players_changed.connect(_redraw)
	Net.player_message.connect(_on_player_message)
	Game.player_reconnected.connect(_send)
	_redraw()

	for id in Game.player_ids():
		assigned[id] = problems.pick_random()
		_send(id)
	$Timer.start()

func _send(id: String) -> void:
	if not assigned.has(id) or Game.problems.any(func(a): return a.player == id):
		return
	Net.send_to(id, {
		"type": "problem",
		"problem": assigned[id]
	})

func _fill(template: String, words: Array) -> String:
	var parts = template.split("___")
	var text = parts[0]
	for i in range(1, parts.size()):
		text += (str(words[i - 1]) if i - 1 < words.size() else "___") + parts[i]
	return text

func _on_player_message(id: String, data: Variant) -> void:
	if not Game.players.has(id) or typeof(data) != TYPE_DICTIONARY: return
	if data.get("blanks"):
		if not assigned.has(id) or Game.problems.any(func(a): return a.player == id): return
		Game.problems.append({
			"player": id,
			"text": _fill(assigned[id].text, data.get("blanks"))
		})
		_redraw()

		if len(Game.problems) == assigned.size() && $Timer.time_left > 5:
			# all players answered
			$Timer.stop()
			$AudioStreamPlayer.stop()
			$AudioStreamPlayer3.play() # Looks like we finished early...
			await $AudioStreamPlayer3.finished
			Game.goto_screen("details_tutorial")
		elif len(Game.problems) == assigned.size():
			$Timer.stop()
			$AudioStreamPlayer.stop()
			$AudioStreamPlayer2.play() # Okay! Moving on...
			await $AudioStreamPlayer2.finished
			Game.goto_screen("details_tutorial")
			

func _redraw() -> void:
	for child in submitted_list.get_children():
		child.queue_free()
	for answer in Game.problems:
		if answer.get("auto", false) or not Game.players.has(answer.player):
			continue
		var panel := submitted_template.duplicate()
		panel.get_node("Label").text = Game.initials(Game.players[answer.player].name)
		submitted_list.add_child(panel)

func _exit_tree() -> void:
	submitted_template.queue_free()

func timeout() -> void:
	$Timer.stop()
	var answered = Game.problems.map(func(a): return a.player)
	for id in assigned:
		if id in answered:
			continue
		var words = fallback_answers.duplicate()
		words.shuffle()
		Game.problems.append({
			"player": id,
			"text": _fill(assigned[id].text, words.slice(0, assigned[id].blanks)),
			"auto": true
		})
