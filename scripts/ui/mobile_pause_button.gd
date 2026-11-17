extends Button

func _ready() -> void :
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = DisplayServer.is_touchscreen_available() or bool(ProjectSettings.get_setting("input_devices/pointing/emulate_touch_from_mouse"))
	pressed.connect(_on_pressed)

func _on_pressed() -> void :
	var players: = get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	var player = players[0]
	if player.has_method("toggle_pause_menu"):
		player.toggle_pause_menu()
	elif player.has_method("_toggle_pause_menu"):
		player._toggle_pause_menu()
