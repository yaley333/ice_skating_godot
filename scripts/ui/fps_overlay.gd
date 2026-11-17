extends CanvasLayer

const SETTINGS_PATH: = "user://settings.cfg"
const SETTINGS_SECTION: = "settings"

@onready var label: Label = $Panel / Label

var _accum: = 0.0
var _interval: = 0.2
var _show: = false

func _process(delta: float) -> void :
	if get_tree().paused:
		visible = false
		return
	visible = _show
	if not _show:
		return
	_accum += delta
	if _accum < _interval:
		return
	_accum = 0.0
	if label:
		label.text = "FPS: %d" % Engine.get_frames_per_second()

func _ready() -> void :
	add_to_group("fps_overlay")
	_apply_settings()

func _apply_settings() -> void :
	var cfg: = ConfigFile.new()
	var show: = false
	if cfg.load(SETTINGS_PATH) == OK:
		show = bool(cfg.get_value(SETTINGS_SECTION, "show_fps", false))
	_show = show
