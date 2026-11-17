extends Node3D

const SETTINGS_PATH: = "user://settings.cfg"
const SETTINGS_SECTION: = "settings"

@onready var world_env: WorldEnvironment = $WorldEnvironment
@onready var sun_light: DirectionalLight3D = $DirectionalLight3D

func _ready() -> void :
	add_to_group("graphics_settings")
	_apply_settings()

func _apply_settings() -> void :
	var cfg: = ConfigFile.new()
	var aa: = true
	var ssao: = true
	var ssr: = true
	var ssil: = true
	var sdfgi: = false
	var scale: = 100.0
	if cfg.load(SETTINGS_PATH) == OK:
		aa = bool(cfg.get_value(SETTINGS_SECTION, "graphics_aa", true))
		ssao = bool(cfg.get_value(SETTINGS_SECTION, "graphics_ssao", true))
		ssr = bool(cfg.get_value(SETTINGS_SECTION, "graphics_ssr", true))
		ssil = bool(cfg.get_value(SETTINGS_SECTION, "graphics_ssil", true))
		sdfgi = bool(cfg.get_value(SETTINGS_SECTION, "graphics_sdfgi", false))
		scale = float(cfg.get_value(SETTINGS_SECTION, "render_scale", 100))
	_apply_graphics(aa, ssao, ssr, ssil, sdfgi, scale)

func _apply_graphics(aa: bool, ssao: bool, ssr: bool, ssil: bool, sdfgi: bool, scale: float) -> void :
	if world_env and world_env.environment:
		var env: = world_env.environment
		env.ssao_enabled = ssao
		env.ssr_enabled = ssr
		env.ssil_enabled = ssil
		env.sdfgi_enabled = sdfgi
	if sun_light:
		sun_light.shadow_enabled = true
	var vp: = get_viewport()
	if aa:
		vp.msaa_3d = Viewport.MSAA_4X
		vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
	else:
		vp.msaa_3d = Viewport.MSAA_DISABLED
		vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
	var clamped = clamp(scale, 50.0, 120.0) / 100.0
	vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
	vp.scaling_3d_scale = clamped
