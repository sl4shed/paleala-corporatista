extends Control

var answers = [];
var questions = [
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

func _ready() -> void:
	Game.players_changed.connect(_redraw)
	Net.player_message.connect(_on_player_message)
	_redraw()

func _on_player_message(id: String, data: Variant) -> void:
	if not Game.players.has(id) or typeof(data) != TYPE_DICTIONARY: return
	if data.get("blanks"):
		answers.append({
			"player": id,
			"blanks": data.get("blanks")
		})

func _redraw() -> void:
	pass
