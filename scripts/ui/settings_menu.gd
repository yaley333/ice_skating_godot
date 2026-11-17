extends Control

@export var menu_scene_path: String = "res://ui/main_menu3d.tscn"
@export var return_to_pause: = false
@export var background_alpha_override: = -1.0
var pause_menu_ref: Control = null
var _ui_texts: = {}

const SETTINGS_PATH: = "user://settings.cfg"
const SECTION: = "settings"
const CAMERA_MODE_LABELS: = ["Стандартный", "Комфорт", "Комфорт+", "Динамичный", "Статичный"]
const CAMERA_MODE_KEYS: = ["standard", "smooth", "comfort_plus", "game", "static"]
const CAMERA_VIEW_LABELS: = ["3-е лицо", "1-е лицо"]
const CAMERA_VIEW_KEYS: = ["third", "first"]
const DEFAULT_SENSITIVITY: = 50
const DEFAULT_SFX: = 70
const DEFAULT_MUSIC: = 70
const DEFAULT_FOV: = 75
const DEFAULT_DISTANCE: = 100
const DEFAULT_CAMERA_MODE_KEY: = "static"
const DEFAULT_CAMERA_VIEW_KEY: = "third"
const DEFAULT_AA: = true
const DEFAULT_SSAO: = true
const DEFAULT_SSR: = true
const DEFAULT_SSIL: = true
const DEFAULT_SDFGI: = false
const DEFAULT_RENDER_SCALE: = 100
const DEFAULT_SHOW_FPS: = false
const DEFAULT_LANGUAGE: = "system"
const SCROLL_STEP: = 120.0
const BUTTONS_PANEL_HEIGHT: = 96.0
const BUTTONS_PANEL_MARGIN_X: = 24.0
const BUTTONS_PANEL_MARGIN_Y: = 10.0
const LANGUAGE_LABELS: = ["Русский", "English", "Deutsch", "Français", "Español", "Italiano"]
const LANGUAGE_LOCALES: = ["ru", "en", "de", "fr", "es", "it"]

var _scroll_base_min_y: = -1.0

@onready var sensitivity_slider: HSlider = $Center / Panel / Scroll / VBox / SensitivitySlider
@onready var sfx_slider: HSlider = $Center / Panel / Scroll / VBox / SfxSlider
@onready var music_slider: HSlider = $Center / Panel / Scroll / VBox / MusicSlider
@onready var language_option: OptionButton = $Center / Panel / Scroll / VBox / LanguageRow / LanguageOption
@onready var graphics_scale_slider: HSlider = $Center / Panel / Scroll / VBox / GraphicsScaleSlider
@onready var graphics_scale_value: Label = $Center / Panel / Scroll / VBox / GraphicsScaleRow / GraphicsScaleValue
@onready var aa_check: CheckBox = $Center / Panel / Scroll / VBox / AA_Row / AA_Check
@onready var ssao_check: CheckBox = $Center / Panel / Scroll / VBox / SSAO_Row / SSAO_Check
@onready var ssr_check: CheckBox = $Center / Panel / Scroll / VBox / SSR_Row / SSR_Check
@onready var ssil_check: CheckBox = $Center / Panel / Scroll / VBox / SSIL_Row / SSIL_Check
@onready var sdfgi_check: CheckBox = $Center / Panel / Scroll / VBox / SDFGI_Row / SDFGI_Check
@onready var show_fps_check: CheckBox = $Center / Panel / Scroll / VBox / ShowFpsRow / ShowFpsCheck
@onready var tips_button: Button = $Center / Panel / Scroll / VBox / GraphicsTipsButton
@onready var tips_popup: Control = $GraphicsTipsOverlay
@onready var fov_slider: HSlider = $Center / Panel / Scroll / VBox / CameraFovSlider
@onready var distance_slider: HSlider = $Center / Panel / Scroll / VBox / CameraDistanceSlider
@onready var camera_option: OptionButton = $Center / Panel / Scroll / VBox / CameraRow / CameraOption
@onready var camera_view_option: OptionButton = $Center / Panel / Scroll / VBox / CameraViewRow / CameraViewOption
@onready var background_rect: ColorRect = $Background
@onready var scroll_container: ScrollContainer = $Center / Panel / Scroll
@onready var panel_container: PanelContainer = $Center / Panel
@onready var buttons_panel: PanelContainer = $ButtonsPanel
@onready var spacer_bottom: Control = $Center / Panel / Scroll / VBox / SpacerBottom

@onready var sensitivity_value: Label = $Center / Panel / Scroll / VBox / SensitivityRow / SensitivityValue
@onready var sfx_value: Label = $Center / Panel / Scroll / VBox / SfxRow / SfxValue
@onready var music_value: Label = $Center / Panel / Scroll / VBox / MusicRow / MusicValue
@onready var fov_value: Label = $Center / Panel / Scroll / VBox / CameraFovRow / CameraFovValue
@onready var distance_value: Label = $Center / Panel / Scroll / VBox / CameraDistanceRow / CameraDistanceValue
@onready var title_label: Label = $Center / Panel / Scroll / VBox / Title
@onready var sensitivity_label: Label = $Center / Panel / Scroll / VBox / SensitivityRow / SensitivityLabel
@onready var sfx_label: Label = $Center / Panel / Scroll / VBox / SfxRow / SfxLabel
@onready var music_label: Label = $Center / Panel / Scroll / VBox / MusicRow / MusicLabel
@onready var language_label: Label = $Center / Panel / Scroll / VBox / LanguageRow / LanguageLabel
@onready var graphics_section_label: Label = $Center / Panel / Scroll / VBox / GraphicsSectionLabel
@onready var graphics_scale_label: Label = $Center / Panel / Scroll / VBox / GraphicsScaleRow / GraphicsScaleLabel
@onready var aa_label: Label = $Center / Panel / Scroll / VBox / AA_Row / AA_Label
@onready var ssao_label: Label = $Center / Panel / Scroll / VBox / SSAO_Row / SSAO_Label
@onready var ssr_label: Label = $Center / Panel / Scroll / VBox / SSR_Row / SSR_Label
@onready var ssil_label: Label = $Center / Panel / Scroll / VBox / SSIL_Row / SSIL_Label
@onready var sdfgi_label: Label = $Center / Panel / Scroll / VBox / SDFGI_Row / SDFGI_Label
@onready var show_fps_label: Label = $Center / Panel / Scroll / VBox / ShowFpsRow / ShowFpsLabel
@onready var graphics_tips_button: Button = $Center / Panel / Scroll / VBox / GraphicsTipsButton
@onready var camera_section_label: Label = $Center / Panel / Scroll / VBox / CameraSectionLabel
@onready var camera_fov_label: Label = $Center / Panel / Scroll / VBox / CameraFovRow / CameraFovLabel
@onready var camera_distance_label: Label = $Center / Panel / Scroll / VBox / CameraDistanceRow / CameraDistanceLabel
@onready var camera_label: Label = $Center / Panel / Scroll / VBox / CameraRow / CameraLabel
@onready var camera_view_label: Label = $Center / Panel / Scroll / VBox / CameraViewRow / CameraViewLabel
@onready var back_button: Button = $ButtonsPanel / ButtonsVBox / ButtonsRow / BackButton
@onready var reset_button: Button = $ButtonsPanel / ButtonsVBox / ButtonsRow / ResetButton
@onready var save_button: Button = $ButtonsPanel / ButtonsVBox / ButtonsRow / SaveButton
@onready var tips_title: Label = $GraphicsTipsOverlay / TipsCenter / TipsPanel / TipsVBox / TipsTitle
@onready var tips_text: Label = $GraphicsTipsOverlay / TipsCenter / TipsPanel / TipsVBox / TipsText
@onready var tips_close: Button = $GraphicsTipsOverlay / TipsCenter / TipsPanel / TipsVBox / TipsClose
@onready var snowflakes_root: Node = get_node_or_null("Snowflakes")

@onready var saved_label: Label = $ButtonsPanel / ButtonsVBox / SavedLabel

func _ready() -> void :
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("settings_menu")
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if scroll_container and _scroll_base_min_y < 0.0:
		_scroll_base_min_y = scroll_container.custom_minimum_size.y
	if panel_container:
		panel_container.resized.connect(_layout_for_viewport)
		panel_container.item_rect_changed.connect(_layout_for_viewport)
	var vp: Viewport = get_viewport()
	if vp:
		vp.size_changed.connect(_layout_for_viewport)
	if background_rect:
		var c = background_rect.color
		if background_alpha_override >= 0.0:
			c.a = clamp(background_alpha_override, 0.0, 1.0)
		elif return_to_pause:
			c.a = 0.55
		else:
			c.a = 1.0
		background_rect.color = c
	_setup_languages()
	_setup_camera_modes()
	_setup_camera_views()
	_load_settings()
	_update_labels()
	_apply_ui_texts(TranslationServer.get_locale())
	_layout_for_viewport()
	_start_menu_fx()

func _on_back_pressed() -> void :
	if return_to_pause and pause_menu_ref:
		pause_menu_ref.visible = true
		queue_free()
		return
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().change_scene_to_file(menu_scene_path)

func _on_save_pressed() -> void :
	_save_settings()
	get_tree().call_group("player", "_apply_settings")
	get_tree().call_group("music_settings", "_apply_settings")
	get_tree().call_group("camera_head", "_apply_settings")
	get_tree().call_group("graphics_settings", "_apply_settings")
	get_tree().call_group("fps_overlay", "_apply_settings")
	saved_label.text = _ui_texts.get("saved", "Settings saved")

func _on_reset_pressed() -> void :
	sensitivity_slider.value = DEFAULT_SENSITIVITY
	sfx_slider.value = DEFAULT_SFX
	music_slider.value = DEFAULT_MUSIC
	_apply_language(DEFAULT_LANGUAGE)
	fov_slider.value = DEFAULT_FOV
	distance_slider.value = DEFAULT_DISTANCE
	graphics_scale_slider.value = DEFAULT_RENDER_SCALE
	aa_check.button_pressed = DEFAULT_AA
	ssao_check.button_pressed = DEFAULT_SSAO
	ssr_check.button_pressed = DEFAULT_SSR
	ssil_check.button_pressed = DEFAULT_SSIL
	sdfgi_check.button_pressed = DEFAULT_SDFGI
	show_fps_check.button_pressed = DEFAULT_SHOW_FPS
	if camera_option:
		camera_option.select(max(CAMERA_MODE_KEYS.find(DEFAULT_CAMERA_MODE_KEY), 0))
	if camera_view_option:
		camera_view_option.select(max(CAMERA_VIEW_KEYS.find(DEFAULT_CAMERA_VIEW_KEY), 0))
	_update_labels()
	_save_settings()
	get_tree().call_group("player", "_apply_settings")
	get_tree().call_group("music_settings", "_apply_settings")
	get_tree().call_group("camera_head", "_apply_settings")
	get_tree().call_group("graphics_settings", "_apply_settings")
	get_tree().call_group("fps_overlay", "_apply_settings")
	saved_label.text = _ui_texts.get("reset_done", "Settings reset")

func _unhandled_input(event):
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		_on_back_pressed()
		return
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_UP:
			_scroll_by( - SCROLL_STEP)
			return
		if event.keycode == KEY_DOWN:
			_scroll_by(SCROLL_STEP)
			return
	if event is InputEventScreenDrag:
		_scroll_by( - event.relative.y)
		return

func _on_sensitivity_changed(value: float) -> void :
	sensitivity_value.text = str(int(value))
	saved_label.text = ""

func _on_sfx_changed(value: float) -> void :
	sfx_value.text = str(int(value))
	saved_label.text = ""

func _on_music_changed(value: float) -> void :
	music_value.text = str(int(value))
	saved_label.text = ""

func _on_language_selected(index: int) -> void :
	if index >= 0 and index < LANGUAGE_LOCALES.size():
		_apply_language(LANGUAGE_LOCALES[index])
	saved_label.text = ""

func _on_graphics_scale_changed(value: float) -> void :
	graphics_scale_value.text = str(int(value))
	saved_label.text = ""

func _on_aa_toggled(_v: bool) -> void :
	saved_label.text = ""

func _on_ssao_toggled(_v: bool) -> void :
	saved_label.text = ""

func _on_ssr_toggled(_v: bool) -> void :
	saved_label.text = ""

func _on_ssil_toggled(_v: bool) -> void :
	saved_label.text = ""

func _on_sdfgi_toggled(_v: bool) -> void :
	saved_label.text = ""

func _on_show_fps_toggled(_v: bool) -> void :
	saved_label.text = ""

func _on_graphics_tips_pressed() -> void :
	if tips_popup:
		tips_popup.visible = true

func _on_graphics_tips_close() -> void :
	if tips_popup:
		tips_popup.visible = false

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

func _on_fov_changed(value: float) -> void :
	fov_value.text = str(int(value))
	saved_label.text = ""

func _on_distance_changed(value: float) -> void :
	distance_value.text = str(int(value))
	saved_label.text = ""

func _on_camera_mode_selected(_index: int) -> void :
	saved_label.text = ""

func _on_camera_view_selected(_index: int) -> void :
	saved_label.text = ""

func _scroll_by(delta: float) -> void :
	if not scroll_container:
		return
	var bar: ScrollBar = scroll_container.get_v_scroll_bar()
	if bar:
		scroll_container.scroll_vertical = clamp(scroll_container.scroll_vertical + delta, 0.0, bar.max_value)
	else:
		scroll_container.scroll_vertical += delta

func _layout_for_viewport() -> void :
	_adjust_scroll_height()
	_layout_buttons_panel()

func _adjust_scroll_height() -> void :
	if not scroll_container:
		return
	if _scroll_base_min_y < 0.0:
		_scroll_base_min_y = scroll_container.custom_minimum_size.y
	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	var reserved: float = BUTTONS_PANEL_HEIGHT + BUTTONS_PANEL_MARGIN_Y * 2.0
	var max_available: float = vp_size.y - reserved - 24.0
	var target: float = _scroll_base_min_y
	if max_available > 0.0:
		target = float(min(_scroll_base_min_y, max_available))
	scroll_container.custom_minimum_size.y = float(max(0.0, target))

func _layout_buttons_panel() -> void :
	if not panel_container or not buttons_panel:
		return
	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	var r: Rect2 = panel_container.get_global_rect()
	var top_left: Vector2 = r.position - global_position
	var desired_y: float = top_left.y + r.size.y + BUTTONS_PANEL_MARGIN_Y
	var max_y: float = vp_size.y - BUTTONS_PANEL_HEIGHT - BUTTONS_PANEL_MARGIN_Y
	var y: float = float(min(desired_y, max_y))
	var width: float = float(min(r.size.x, vp_size.x - BUTTONS_PANEL_MARGIN_X * 2.0))
	if width < 200.0:
		width = r.size.x
	var x: float = float(clamp(top_left.x, BUTTONS_PANEL_MARGIN_X, vp_size.x - BUTTONS_PANEL_MARGIN_X - width))
	buttons_panel.position = Vector2(x, y)
	buttons_panel.size = Vector2(width, BUTTONS_PANEL_HEIGHT)
	if spacer_bottom:
		var overlay_extra: float = 0.0
		if y < desired_y - 0.5:
			overlay_extra = BUTTONS_PANEL_HEIGHT + BUTTONS_PANEL_MARGIN_Y
		spacer_bottom.custom_minimum_size.y = 10.0 + overlay_extra

func _update_labels() -> void :
	sensitivity_value.text = str(int(sensitivity_slider.value))
	sfx_value.text = str(int(sfx_slider.value))
	music_value.text = str(int(music_slider.value))
	fov_value.text = str(int(fov_slider.value))
	distance_value.text = str(int(distance_slider.value))
	graphics_scale_value.text = str(int(graphics_scale_slider.value))

func _setup_camera_modes() -> void :
	if not camera_option:
		return
	camera_option.clear()
	for label in CAMERA_MODE_LABELS:
		camera_option.add_item(label)

func _setup_camera_views() -> void :
	if not camera_view_option:
		return
	camera_view_option.clear()
	for label in CAMERA_VIEW_LABELS:
		camera_view_option.add_item(label)

func _update_camera_mode_labels(labels: Array) -> void :
	if not camera_option:
		return
	var sel: = camera_option.selected
	camera_option.clear()
	for label in labels:
		camera_option.add_item(label)
	if sel < 0:
		sel = 0
	camera_option.select(sel)

func _update_camera_view_labels(labels: Array) -> void :
	if not camera_view_option:
		return
	var sel: = camera_view_option.selected
	camera_view_option.clear()
	for label in labels:
		camera_view_option.add_item(label)
	if sel < 0:
		sel = 0
	camera_view_option.select(sel)

func _setup_languages() -> void :
	if not language_option:
		return
	language_option.clear()
	for label in LANGUAGE_LABELS:
		language_option.add_item(label)

func _apply_language(key: String) -> void :
	var locale: = _resolve_language(key)
	TranslationServer.set_locale(locale)
	_apply_ui_texts(locale)
	if language_option:
		var idx: = LANGUAGE_LOCALES.find(locale)
		if idx < 0:
			idx = 0
		language_option.select(idx)

func _resolve_language(key: String) -> String:
	if key == "system":
		return _resolve_language(OS.get_locale())
	var lower = key.to_lower()
	for loc in LANGUAGE_LOCALES:
		if lower == loc.to_lower():
			return loc
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

func _apply_ui_texts(locale: String) -> void :
	var lang: = _resolve_language(locale)
	var t: = {
		"ru": {
			"title": "Настройки", 
			"sensitivity": "Чувствительность", 
			"sfx": "Звуки", 
			"music": "Музыка", 
			"language": "Язык", 
			"graphics_section": "Настройки графики", 
			"resolution": "Разрешение", 
			"aa": "Сглаживание", 
			"ssao": "SSAO", 
			"ssr": "SSR", 
			"ssil": "SSIL", 
			"sdfgi": "SDFGI", 
			"show_fps": "Показывать FPS", 
			"tips_button": "Советы для слабых устройств", 
			"camera_section": "Настройки камеры", 
			"fov": "FOV (угол обзора)", 
			"distance": "Дистанция", 
			"camera": "Камера", 
			"camera_view": "Вид камеры", 
			"camera_modes": ["Стандартный", "Комфорт", "Комфорт+", "Динамический", "Статичный"], 
			"camera_views": ["3-е лицо", "1-е лицо"], 
			"back": "Назад", 
			"reset": "Сброс", 
			"save": "Сохранить", 
			"tips_title": "Рекомендации", 
			"tips_text": "Нужно больше FPS? Сначала отключите SDFGI и сглаживание - это дает самый большой прирост. Затем понизьте разрешение. Дополнительно можно отключить SSAO, SSR и SSIL - обычно +8-10 FPS.", 
			"tips_close": "Закрыть", 
			"saved": "Настройки сохранены", 
			"reset_done": "Настройки сброшены", 
		}, 
		"en": {
			"title": "Settings", 
			"sensitivity": "Sensitivity", 
			"sfx": "SFX", 
			"music": "Music", 
			"language": "Language", 
			"graphics_section": "Graphics Settings", 
			"resolution": "Resolution", 
			"aa": "Anti-aliasing", 
			"ssao": "SSAO", 
			"ssr": "SSR", 
			"ssil": "SSIL", 
			"sdfgi": "SDFGI", 
			"show_fps": "Show FPS", 
			"tips_button": "Tips for low-end devices", 
			"camera_section": "Camera Settings", 
			"fov": "FOV (field of view)", 
			"distance": "Distance", 
			"camera": "Camera", 
			"camera_view": "Camera view", 
			"camera_modes": ["Standard", "Comfort", "Comfort+", "Dynamic", "Static"], 
			"camera_views": ["Third person", "First person"], 
			"back": "Back", 
			"reset": "Reset", 
			"save": "Save", 
			"tips_title": "Tips", 
			"tips_text": "Want more FPS? First disable SDFGI and anti-aliasing - that gives the biggest boost. Then lower the resolution. You can also disable SSAO, SSR, and SSIL - usually +8-10 FPS.", 
			"tips_close": "Close", 
			"saved": "Settings saved", 
			"reset_done": "Settings reset", 
		}, 
		"de": {
			"title": "Einstellungen", 
			"sensitivity": "Empfindlichkeit", 
			"sfx": "Soundeffekte", 
			"music": "Musik", 
			"language": "Sprache", 
			"graphics_section": "Grafikeinstellungen", 
			"resolution": "Aufloesung", 
			"aa": "Kantenglaettung", 
			"ssao": "SSAO", 
			"ssr": "SSR", 
			"ssil": "SSIL", 
			"sdfgi": "SDFGI", 
			"show_fps": "FPS anzeigen", 
			"tips_button": "Tipps fuer schwache Geraete", 
			"camera_section": "Kameraeinstellungen", 
			"fov": "FOV (Sichtfeld)", 
			"distance": "Distanz", 
			"camera": "Kamera", 
			"camera_view": "Kameraansicht", 
			"camera_modes": ["Standard", "Komfort", "Komfort+", "Dynamisch", "Statisch"], 
			"camera_views": ["Dritte Person", "Erste Person"], 
			"back": "Zurueck", 
			"reset": "Zuruecksetzen", 
			"save": "Speichern", 
			"tips_title": "Tipps", 
			"tips_text": "Mehr FPS? Zuerst SDFGI und Kantenglaettung deaktivieren - das bringt den groessten Schub. Dann die Aufloesung senken. Zusaetzlich SSAO, SSR und SSIL deaktivieren - meist +8-10 FPS.", 
			"tips_close": "Schliessen", 
			"saved": "Einstellungen gespeichert", 
			"reset_done": "Einstellungen zurueckgesetzt", 
		}, 
		"fr": {
			"title": "Parametres", 
			"sensitivity": "Sensibilite", 
			"sfx": "SFX", 
			"music": "Musique", 
			"language": "Langue", 
			"graphics_section": "Parametres graphiques", 
			"resolution": "Resolution", 
			"aa": "Anticrenelage", 
			"ssao": "SSAO", 
			"ssr": "SSR", 
			"ssil": "SSIL", 
			"sdfgi": "SDFGI", 
			"show_fps": "Afficher les FPS", 
			"tips_button": "Conseils pour PC faibles", 
			"camera_section": "Parametres camera", 
			"fov": "FOV (champ de vision)", 
			"distance": "Distance", 
			"camera": "Camera", 
			"camera_view": "Vue de la camera", 
			"camera_modes": ["Standard", "Confort", "Confort+", "Dynamique", "Statique"], 
			"camera_views": ["Troisieme personne", "Premiere personne"], 
			"back": "Retour", 
			"reset": "Reinitialiser", 
			"save": "Enregistrer", 
			"tips_title": "Conseils", 
			"tips_text": "Plus de FPS ? Desactivez d'abord SDFGI et l'anticrenelage - c'est le plus efficace. Ensuite, baissez la resolution. Vous pouvez aussi desactiver SSAO, SSR et SSIL - en general +8-10 FPS.", 
			"tips_close": "Fermer", 
			"saved": "Parametres enregistres", 
			"reset_done": "Parametres reinitialises", 
		}, 
		"es": {
			"title": "Ajustes", 
			"sensitivity": "Sensibilidad", 
			"sfx": "Efectos", 
			"music": "Musica", 
			"language": "Idioma", 
			"graphics_section": "Ajustes graficos", 
			"resolution": "Resolucion", 
			"aa": "Antialiasing", 
			"ssao": "SSAO", 
			"ssr": "SSR", 
			"ssil": "SSIL", 
			"sdfgi": "SDFGI", 
			"show_fps": "Mostrar FPS", 
			"tips_button": "Consejos para equipos modestos", 
			"camera_section": "Ajustes de camara", 
			"fov": "FOV (campo de vision)", 
			"distance": "Distancia", 
			"camera": "Camara", 
			"camera_view": "Vista de camara", 
			"camera_modes": ["Estandar", "Confort", "Confort+", "Dinamico", "Estatico"], 
			"camera_views": ["Tercera persona", "Primera persona"], 
			"back": "Atras", 
			"reset": "Restablecer", 
			"save": "Guardar", 
			"tips_title": "Consejos", 
			"tips_text": "Mas FPS? Primero desactiva SDFGI y el antialiasing - es lo que mas mejora. Luego baja la resolucion. Tambien puedes desactivar SSAO, SSR y SSIL - normalmente +8-10 FPS.", 
			"tips_close": "Cerrar", 
			"saved": "Ajustes guardados", 
			"reset_done": "Ajustes restablecidos", 
		}, 
		"it": {
			"title": "Impostazioni", 
			"sensitivity": "Sensibilita", 
			"sfx": "Effetti", 
			"music": "Musica", 
			"language": "Lingua", 
			"graphics_section": "Impostazioni grafiche", 
			"resolution": "Risoluzione", 
			"aa": "Antialiasing", 
			"ssao": "SSAO", 
			"ssr": "SSR", 
			"ssil": "SSIL", 
			"sdfgi": "SDFGI", 
			"show_fps": "Mostra FPS", 
			"tips_button": "Consigli per PC deboli", 
			"camera_section": "Impostazioni camera", 
			"fov": "FOV (campo visivo)", 
			"distance": "Distanza", 
			"camera": "Camera", 
			"camera_view": "Vista camera", 
			"camera_modes": ["Standard", "Comfort", "Comfort+", "Dinamico", "Statico"], 
			"camera_views": ["Terza persona", "Prima persona"], 
			"back": "Indietro", 
			"reset": "Ripristina", 
			"save": "Salva", 
			"tips_title": "Consigli", 
			"tips_text": "Vuoi piu FPS? Disattiva prima SDFGI e antialiasing - e il miglior incremento. Poi riduci la risoluzione. Puoi anche disattivare SSAO, SSR e SSIL - di solito +8-10 FPS.", 
			"tips_close": "Chiudi", 
			"saved": "Impostazioni salvate", 
			"reset_done": "Impostazioni ripristinate", 
		}, 
	}
	var d = t.get(lang, t["en"])
	_ui_texts = d
	if title_label: title_label.text = d["title"]
	if sensitivity_label: sensitivity_label.text = d["sensitivity"]
	if sfx_label: sfx_label.text = d["sfx"]
	if music_label: music_label.text = d["music"]
	if language_label: language_label.text = d["language"]
	if graphics_section_label: graphics_section_label.text = d["graphics_section"]
	if graphics_scale_label: graphics_scale_label.text = d["resolution"]
	if aa_label: aa_label.text = d["aa"]
	if ssao_label: ssao_label.text = d["ssao"]
	if ssr_label: ssr_label.text = d["ssr"]
	if ssil_label: ssil_label.text = d["ssil"]
	if sdfgi_label: sdfgi_label.text = d["sdfgi"]
	if show_fps_label: show_fps_label.text = d["show_fps"]
	if graphics_tips_button: graphics_tips_button.text = d["tips_button"]
	if camera_section_label: camera_section_label.text = d["camera_section"]
	if camera_fov_label: camera_fov_label.text = d["fov"]
	if camera_distance_label: camera_distance_label.text = d["distance"]
	if camera_label: camera_label.text = d["camera"]
	if camera_view_label: camera_view_label.text = d["camera_view"]
	if back_button: back_button.text = d["back"]
	if reset_button: reset_button.text = d["reset"]
	if save_button: save_button.text = d["save"]
	if tips_title: tips_title.text = d["tips_title"]
	if tips_text: tips_text.text = d["tips_text"]
	if tips_close: tips_close.text = d["tips_close"]
	var cm = d.get("camera_modes", CAMERA_MODE_LABELS)
	_update_camera_mode_labels(cm)
	var cv = d.get("camera_views", CAMERA_VIEW_LABELS)
	_update_camera_view_labels(cv)

func _load_settings() -> void :
	var cfg: = ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		sensitivity_slider.value = cfg.get_value(SECTION, "sensitivity", DEFAULT_SENSITIVITY)
		sfx_slider.value = cfg.get_value(SECTION, "sfx_volume", DEFAULT_SFX)
		music_slider.value = cfg.get_value(SECTION, "music_volume", DEFAULT_MUSIC)
		var lang_key = str(cfg.get_value(SECTION, "language", DEFAULT_LANGUAGE))
		_apply_language(lang_key)
		fov_slider.value = cfg.get_value(SECTION, "camera_fov", DEFAULT_FOV)
		distance_slider.value = cfg.get_value(SECTION, "camera_distance", DEFAULT_DISTANCE)
		graphics_scale_slider.value = cfg.get_value(SECTION, "render_scale", DEFAULT_RENDER_SCALE)
		aa_check.button_pressed = cfg.get_value(SECTION, "graphics_aa", DEFAULT_AA)
		ssao_check.button_pressed = cfg.get_value(SECTION, "graphics_ssao", DEFAULT_SSAO)
		ssr_check.button_pressed = cfg.get_value(SECTION, "graphics_ssr", DEFAULT_SSR)
		ssil_check.button_pressed = cfg.get_value(SECTION, "graphics_ssil", DEFAULT_SSIL)
		sdfgi_check.button_pressed = cfg.get_value(SECTION, "graphics_sdfgi", DEFAULT_SDFGI)
		show_fps_check.button_pressed = cfg.get_value(SECTION, "show_fps", DEFAULT_SHOW_FPS)
		var mode_key = str(cfg.get_value(SECTION, "camera_mode", DEFAULT_CAMERA_MODE_KEY))
		var idx: = CAMERA_MODE_KEYS.find(mode_key)
		if idx < 0:
			idx = 0
		if camera_option:
			camera_option.select(idx)
		var raw_view = cfg.get_value(SECTION, "camera_view", DEFAULT_CAMERA_VIEW_KEY)
		var view_key: = ""
		if typeof(raw_view) == TYPE_INT:
			var view_i: = int(raw_view)
			if view_i >= 0 and view_i < CAMERA_VIEW_KEYS.size():
				view_key = CAMERA_VIEW_KEYS[view_i]
		else:
			view_key = str(raw_view)
		var view_idx: = CAMERA_VIEW_KEYS.find(view_key)
		if view_idx < 0:
			view_idx = 0
		if camera_view_option:
			camera_view_option.select(view_idx)
	else:
		_apply_language(DEFAULT_LANGUAGE)

func _save_settings() -> void :
	var cfg: = ConfigFile.new()
	cfg.set_value(SECTION, "sensitivity", int(sensitivity_slider.value))
	cfg.set_value(SECTION, "sfx_volume", int(sfx_slider.value))
	cfg.set_value(SECTION, "music_volume", int(music_slider.value))
	if language_option:
		var lang_idx: = language_option.selected
		if lang_idx < 0:
			lang_idx = 0
		cfg.set_value(SECTION, "language", LANGUAGE_LOCALES[lang_idx])
	cfg.set_value(SECTION, "camera_fov", int(fov_slider.value))
	cfg.set_value(SECTION, "camera_distance", int(distance_slider.value))
	cfg.set_value(SECTION, "render_scale", int(graphics_scale_slider.value))
	cfg.set_value(SECTION, "graphics_aa", aa_check.button_pressed)
	cfg.set_value(SECTION, "graphics_ssao", ssao_check.button_pressed)
	cfg.set_value(SECTION, "graphics_ssr", ssr_check.button_pressed)
	cfg.set_value(SECTION, "graphics_ssil", ssil_check.button_pressed)
	cfg.set_value(SECTION, "graphics_sdfgi", sdfgi_check.button_pressed)
	cfg.set_value(SECTION, "show_fps", show_fps_check.button_pressed)
	if camera_option:
		var idx: = camera_option.selected
		if idx < 0:
			idx = 0
		cfg.set_value(SECTION, "camera_mode", CAMERA_MODE_KEYS[idx])
	if camera_view_option:
		var view_idx: = camera_view_option.selected
		if view_idx < 0:
			view_idx = 0
		cfg.set_value(SECTION, "camera_view", CAMERA_VIEW_KEYS[view_idx])
	cfg.save(SETTINGS_PATH)
