extends Control

const SETTINGS_PATH: = "user://settings.cfg"
const SETTINGS_SECTION: = "settings"

@export var settings_scene_path: String = "res://ui/settings_menu.tscn"
@export var support_scene_path: String = "res://ui/support_menu.tscn"
@export var main_menu_scene_path: String = "res://ui/main_menu3d.tscn"
@onready var snowflakes_root: Node = $Snowflakes

func _ready() -> void :
	process_mode = Node.PROCESS_MODE_ALWAYS
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_apply_language()
	_start_menu_fx()

func _notification(what: int) -> void :
	if what == NOTIFICATION_VISIBILITY_CHANGED and visible:
		_apply_language()

func _start_menu_fx() -> void :
	if not snowflakes_root:
		return
	var i: = 0
	for n in snowflakes_root.get_children():
		if not (n is CanvasItem):
			continue
		var item: = n as CanvasItem
		var base_pos: Vector2 = item.position
		var t: = create_tween()
		t.set_loops()
		var phase: = float(i) * 0.3
		t.tween_property(item, "position", base_pos + Vector2(0, -18), 2.2 + phase).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		t.tween_property(item, "position", base_pos + Vector2(0, 18), 2.2 + phase).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		var r: = create_tween()
		r.set_loops()
		r.tween_property(item, "rotation", 0.3, 4.0 + phase).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		r.tween_property(item, "rotation", -0.3, 4.0 + phase).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		i += 1

func _on_resume_pressed() -> void :
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	queue_free()

func _on_settings_pressed() -> void :
	var settings_scene: = load(settings_scene_path)
	if settings_scene == null:
		push_warning("settings_scene_path is invalid")
		return
	var settings = settings_scene.instantiate()
	if settings:
		settings.return_to_pause = true
		settings.pause_menu_ref = self
		visible = false
		get_tree().current_scene.add_child(settings)

func _on_quit_pressed() -> void :
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if main_menu_scene_path.is_empty():
		push_warning("main_menu_scene_path is empty")
		return
	get_tree().change_scene_to_file(main_menu_scene_path)

func _on_support_pressed() -> void :
	if support_scene_path.is_empty():
		push_warning("support_scene_path is empty")
		return
	var support_scene: = load(support_scene_path)
	if support_scene == null:
		push_warning("support_scene_path is invalid")
		return
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().change_scene_to_file(support_scene_path)

func _apply_language() -> void :
	var cfg: = ConfigFile.new()
	var lang = "en"
	if cfg.load(SETTINGS_PATH) == OK:
		lang = str(cfg.get_value(SETTINGS_SECTION, "language", "system"))
	lang = _resolve_language(lang)
	var t = {
		"ru": {
			"title": "Пауза", 
			"resume": "Продолжить", 
			"settings": "Настройки", 
			"support": "Поддержать разрабочика", 
			"quit": "Выйти", 
		}, 
		"en": {
			"title": "Paused", 
			"resume": "Resume", 
			"settings": "Settings", 
			"support": "Support Developer", 
			"quit": "Quit", 
		}, 
		"de": {
			"title": "Pause", 
			"resume": "Fortsetzen", 
			"settings": "Einstellungen", 
			"support": "Entwickler unterstutzen", 
			"quit": "Beenden", 
		}, 
		"fr": {
			"title": "Pause", 
			"resume": "Reprendre", 
			"settings": "Parametres", 
			"support": "Soutenir le developpeur", 
			"quit": "Quitter", 
		}, 
		"es": {
			"title": "Pausa", 
			"resume": "Continuar", 
			"settings": "Ajustes", 
			"support": "Apoyar al desarrollador", 
			"quit": "Salir", 
		}, 
		"it": {
			"title": "Pausa", 
			"resume": "Riprendi", 
			"settings": "Impostazioni", 
			"support": "Supporta sviluppatore", 
			"quit": "Esci", 
		}, 
	}
	var d = t.get(lang, t["en"])
	$Center / Panel / VBox / Title.text = d["title"]
	$Center / Panel / VBox / ResumeButton.text = d["resume"]
	$Center / Panel / VBox / SettingsButton.text = d["settings"]
	$Center / Panel / VBox / SupportButton.text = d["support"]
	$Center / Panel / VBox / QuitButton.text = d["quit"]

func _resolve_language(key: String) -> String:
	if key == "system":
		return _resolve_language(OS.get_locale())
	var lower = key.to_lower()
	if lower.begins_with("ru"):
		return "ru"
	if lower.begins_with("de"):
		return "de"
	if lower.begins_with("fr"):
		return "fr"
	if lower.begins_with("es"):
		return "es"
	if lower.begins_with("it"):
		return "it"
	if lower.begins_with("en"):
		return "en"
	return "en"
