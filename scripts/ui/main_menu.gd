extends Control

const SETTINGS_PATH: = "user://settings.cfg"
const SETTINGS_SECTION: = "settings"
const DEFAULT_MUSIC: = 70
const MUSIC_VOL_MIN_DB: = -30.0
const MUSIC_VOL_MAX_DB: = 0.0

@export var play_scene_path: String = "res://ui/map_select.tscn"
@export var settings_scene_path: String = "res://ui/settings_menu.tscn"
@export var support_scene_path: String = "res://ui/support_menu.tscn"
@onready var music_player: AudioStreamPlayer2D = $Music

func _ready() -> void :
	add_to_group("music_settings")
	_apply_settings()
	_apply_language()

func _notification(what: int) -> void :
	if what == NOTIFICATION_VISIBILITY_CHANGED and visible:
		_apply_language()

func _on_play_pressed() -> void :
	if play_scene_path.is_empty():
		push_warning("play_scene_path is empty")
		return
	_save_music_resume_state()
	get_tree().change_scene_to_file(play_scene_path)

func _on_quit_pressed() -> void :
	get_tree().quit()

func _on_settings_pressed() -> void :
	if settings_scene_path.is_empty():
		push_warning("settings_scene_path is empty")
		return
	var current_scene = get_tree().current_scene
	if current_scene and current_scene.name == "MainMenu3d":
		var settings_scene: = load(settings_scene_path)
		if settings_scene == null:
			push_warning("settings_scene_path is invalid")
			return
		var settings = settings_scene.instantiate()
		if settings:
			settings.return_to_pause = true
			settings.pause_menu_ref = self
			settings.background_alpha_override = 0.2
			visible = false
			current_scene.add_child(settings)
		return
	get_tree().change_scene_to_file(settings_scene_path)

func _on_support_pressed() -> void :
	if support_scene_path.is_empty():
		push_warning("support_scene_path is empty")
		return
	var support_scene: = load(support_scene_path)
	if support_scene == null:
		push_warning("support_scene_path is invalid")
		return
	get_tree().change_scene_to_file(support_scene_path)

func _apply_language() -> void :
	var cfg: = ConfigFile.new()
	var lang = "en"
	if cfg.load(SETTINGS_PATH) == OK:
		lang = str(cfg.get_value(SETTINGS_SECTION, "language", "system"))
	lang = _resolve_language(lang)
	var t = {
		"ru": {
			"title": "ICE SKATING", 
			"subtitle": "Покори лёд", 
			"play": "Играть", 
			"settings": "Настройки", 
			"quit": "Выйти", 
			"support": "Поддержать разрабочика", 
		}, 
		"en": {
			"title": "ICE SKATING", 
			"subtitle": "Conquer the ice", 
			"play": "Play", 
			"settings": "Settings", 
			"quit": "Quit", 
			"support": "Support Developer", 
		}, 
		"de": {
			"title": "ICE SKATING", 
			"subtitle": "Erobere das Eis", 
			"play": "Spielen", 
			"settings": "Einstellungen", 
			"quit": "Beenden", 
			"support": "Entwickler unterstutzen", 
		}, 
		"fr": {
			"title": "ICE SKATING", 
			"subtitle": "Conquiers la glace", 
			"play": "Jouer", 
			"settings": "Parametres", 
			"quit": "Quitter", 
			"support": "Soutenir le developpeur", 
		}, 
		"es": {
			"title": "ICE SKATING", 
			"subtitle": "Conquista el hielo", 
			"play": "Jugar", 
			"settings": "Ajustes", 
			"quit": "Salir", 
			"support": "Apoyar al desarrollador", 
		}, 
		"it": {
			"title": "ICE SKATING", 
			"subtitle": "Conquista il ghiaccio", 
			"play": "Gioca", 
			"settings": "Impostazioni", 
			"quit": "Esci", 
			"support": "Supporta sviluppatore", 
		}, 
	}
	var d = t.get(lang, t["en"])
	$Center / Panel / VBox / Title.text = d["title"]
	$Center / Panel / VBox / Subtitle.text = d["subtitle"]
	$Center / Panel / VBox / PlayButton.text = d["play"]
	$Center / Panel / VBox / SettingsButton.text = d["settings"]
	$Center / Panel / VBox / QuitButton.text = d["quit"]
	$SupportButton.text = d["support"]

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

func _apply_settings() -> void :
	var cfg: = ConfigFile.new()
	var music_v: = DEFAULT_MUSIC
	if cfg.load(SETTINGS_PATH) == OK:
		music_v = int(cfg.get_value(SETTINGS_SECTION, "music_volume", DEFAULT_MUSIC))
	if music_player:
		music_player.volume_db = _percent_to_music_db(music_v)

func _save_music_resume_state() -> void :
	if not music_player:
		return
	var cfg: = ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	cfg.set_value(SETTINGS_SECTION, "music_resume_pending", true)
	cfg.set_value(SETTINGS_SECTION, "music_resume_pos", music_player.get_playback_position())
	cfg.save(SETTINGS_PATH)

func _percent_to_music_db(v: int) -> float:
	var t = clamp(float(v) / 100.0, 0.0, 1.0)

	var curved = sqrt(t)
	return lerp(MUSIC_VOL_MIN_DB, MUSIC_VOL_MAX_DB, curved)
