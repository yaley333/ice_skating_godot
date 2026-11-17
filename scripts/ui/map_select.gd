extends Control

@export var main_menu_scene_path: String = "res://ui/main_menu3d.tscn"
@export var world1_scene_path: String = "res://world.tscn"
@export var world2_scene_path: String = "res://world_2.tscn"
@export var world3_scene_path: String = "res://world_3.tscn"
@export var panel_normal: StyleBox
@export var panel_selected: StyleBox

@onready var back_button: Button = $Margin / VBox / TopBar / BackButton
@onready var title_label: Label = $Margin / VBox / TopBar / Title
@onready var start_button: Button = $Margin / VBox / BottomBar / StartButton
@onready var snowflakes_root: Node = $Snowflakes
@onready var loading_overlay: ColorRect = $LoadingOverlay
@onready var loading_label: Label = $LoadingOverlay / LoadingCenter / LoadingLabel
@onready var card_panels: Array[PanelContainer] = [
	$Margin / VBox / CardsScroll / Cards / World1Panel, 
	$Margin / VBox / CardsScroll / Cards / World2Panel, 
	$Margin / VBox / CardsScroll / Cards / World3Panel, 
]
@onready var card_buttons: Array[Button] = [
	$Margin / VBox / CardsScroll / Cards / World1Panel / Margin / World1Button, 
	$Margin / VBox / CardsScroll / Cards / World2Panel / Margin / World2Button, 
	$Margin / VBox / CardsScroll / Cards / World3Panel / Margin / World3Button, 
]

var _selected_index: int = -1
var _is_loading: = false

func _ready() -> void :
	start_button.disabled = true
	for i in card_buttons.size():
		var btn: = card_buttons[i]
		btn.toggle_mode = true
		btn.pressed.connect(_on_card_pressed.bind(i))
	_refresh_selection()
	back_button.pressed.connect(_on_back_pressed)
	start_button.pressed.connect(_on_start_pressed)
	_apply_language()
	_start_menu_fx()

func _apply_language() -> void :
	var cfg: = ConfigFile.new()
	var lang = "en"
	if cfg.load("user://settings.cfg") == OK:
		lang = str(cfg.get_value("settings", "language", "system"))
	lang = _resolve_language(lang)
	var t = {
		"ru": {
			"title": "Выбор карты", 
			"back": "Назад", 
			"start": "Начать игру", 
		}, 
		"en": {
			"title": "Select Map", 
			"back": "Back", 
			"start": "Start Game", 
		}, 
		"de": {
			"title": "Karte wahlen", 
			"back": "Zuruck", 
			"start": "Spiel starten", 
		}, 
		"fr": {
			"title": "Choisir une carte", 
			"back": "Retour", 
			"start": "Demarrer", 
		}, 
		"es": {
			"title": "Seleccionar mapa", 
			"back": "Atras", 
			"start": "Empezar", 
		}, 
		"it": {
			"title": "Seleziona mappa", 
			"back": "Indietro", 
			"start": "Inizia", 
		}, 
	}
	var d = t.get(lang, t["en"])
	if title_label:
		title_label.text = d["title"]
	if back_button:
		back_button.text = d["back"]
	if start_button:
		start_button.text = d["start"]
	if loading_label:
		match lang:
			"ru":
				loading_label.text = "Загрузка..."
			"de":
				loading_label.text = "Laden..."
			"fr":
				loading_label.text = "Chargement..."
			"es":
				loading_label.text = "Cargando..."
			"it":
				loading_label.text = "Caricamento..."
			_:
				loading_label.text = "Loading..."

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

func _on_card_pressed(index: int) -> void :
	_selected_index = index
	_refresh_selection()

func _refresh_selection() -> void :
	if _is_loading:
		return
	for i in card_buttons.size():
		var is_selected: = i == _selected_index
		card_buttons[i].button_pressed = is_selected
		if panel_selected and panel_normal:
			card_panels[i].add_theme_stylebox_override(
				"panel", 
				panel_selected if is_selected else panel_normal
			)
	start_button.disabled = _selected_index < 0

func _on_back_pressed() -> void :
	if main_menu_scene_path.is_empty():
		push_warning("main_menu_scene_path is empty")
		return
	get_tree().change_scene_to_file(main_menu_scene_path)

func _on_start_pressed() -> void :
	if _is_loading:
		return
	var target: = _get_selected_scene_path()
	if target.is_empty():
		push_warning("No map selected")
		return
	_is_loading = true
	if loading_overlay:
		loading_overlay.visible = true
	start_button.disabled = true
	back_button.disabled = true
	for btn in card_buttons:
		btn.disabled = true
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.05).timeout
	get_tree().call_deferred("change_scene_to_file", target)

func _get_selected_scene_path() -> String:
	match _selected_index:
		0:
			return world1_scene_path
		1:
			return world2_scene_path
		2:
			return world3_scene_path
		_:
			return ""
