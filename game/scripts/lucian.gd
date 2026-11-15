extends Control
var lerp_character := false
var current: Control
var current_scale := 1.0

func _ready() -> void:
	current = get_child(0)

func switch(node_name: String) -> void:
	var next := get_node_or_null(node_name)
	if next == null:
		push_warning("Lucian has no %s" % node_name)
		return
	for ch in get_children():
		ch.visible = false
	current = next
	current.visible = true
	current_scale = current.scale.x
	current.scale = Vector2(current_scale, 0)
	lerp_character = true

func _process(delta: float) -> void:
	if lerp_character:
		current.scale = current.scale.lerp(Vector2(current_scale, current_scale), delta * 20)
		if current.scale.y > current_scale * 0.99:
			current.scale.y = current_scale
			lerp_character = false
