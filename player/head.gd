extends Node3D

@export var sensitivity: = 0.003
@export var touch_sensitivity_multiplier: = 1.0
@export_range(0.1, 0.9, 0.05) var touch_look_area_start_ratio: = 0.5
@export var min_pitch: = -60.0
@export var max_pitch: = 60.0

const SETTINGS_PATH: = "user://settings.cfg"
const SETTINGS_SECTION: = "settings"
const SENS_MIN: = 0.001
const SENS_MAX: = 0.01
const CAMERA_MODE_KEYS: = ["standard", "smooth", "comfort_plus", "game", "static"]
const CAMERA_VIEW_KEYS: = ["third", "first"]
const CAMERA_FOV_MIN: = 60.0
const CAMERA_FOV_MAX: = 100.0
const CAMERA_DIST_MIN: = 70.0
const CAMERA_DIST_MAX: = 130.0


@export var max_tilt: = 5.0
@export var tilt_speed: = 5.0
@export var sway_intensity: = 0.03
@export var bounce_intensity: = 0.02
@export var sway_lerp: = 6.0
@export var shoulder_offset: = Vector3(-0.25, 0.12, 0.0)

var pitch: = 0.0
var current_tilt: = 0.0
var tilt_target: = 0.0
var base_transform: = Transform3D.IDENTITY

var prev_horizontal_velocity: = Vector2.ZERO
var camera_offset: = Vector3.ZERO
var camera_mode: = "standard"
var camera_view: = "third"
var base_max_tilt: = 0.0
var base_tilt_speed: = 0.0
var base_sway_intensity: = 0.0
var base_bounce_intensity: = 0.0
var base_sway_lerp: = 0.0
var base_camera_fov: = 75.0
var smooth_rotation: = false
var rotation_lerp: = 10.0
var use_camera_space_movement: = false
var no_interpolation: = false
var target_yaw: = 0.0
var target_pitch: = 0.0
var base_camera_local_origin: = Vector3.ZERO
var base_camera_distance: = 1.0
var camera_distance_scale: = 1.0
var mode_camera_origin: = Vector3.ZERO
var touch_look_index: = -1

@onready var camera_node_tp: Camera3D = $Camera3D
@onready var camera_node_fp: Camera3D = get_node_or_null("Camera3D2")
var camera_node: Camera3D = null
@onready var mobile_joystick: Control = $"../MobileUI/VirtualJoystickLeft"

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	base_transform = transform
	add_to_group("camera_head")
	base_max_tilt = max_tilt
	base_tilt_speed = tilt_speed
	base_sway_intensity = sway_intensity
	base_bounce_intensity = bounce_intensity
	base_sway_lerp = sway_lerp
	target_yaw = rotation.y
	target_pitch = rotation.x
	_apply_settings()

func _physics_process(delta):

	var player = get_parent()
	var velocity: = Vector3.ZERO
	if player and player.has_method("get_velocity"):
		velocity = player.get_velocity()

	var horizontal_velocity = Vector2(velocity.x, velocity.z)
	var speed = horizontal_velocity.length()


	var side_movement = horizontal_velocity.x
	if use_camera_space_movement:
		var local_vel = global_transform.basis.inverse() * Vector3(horizontal_velocity.x, 0.0, horizontal_velocity.y)
		side_movement = local_vel.x
	tilt_target = clamp( - side_movement * max_tilt / 10.0, - max_tilt, max_tilt)
	if no_interpolation:
		current_tilt = tilt_target
	else:
		current_tilt = lerp(current_tilt, tilt_target, tilt_speed * delta)
	rotation.z = deg_to_rad(current_tilt)


	var sway_target = side_movement * sway_intensity
	if no_interpolation:
		camera_offset.x = sway_target
	else:
		camera_offset.x = lerp(camera_offset.x, sway_target, sway_lerp * delta)


	var accel = horizontal_velocity.length() - prev_horizontal_velocity.length()
	var bounce_target = clamp(accel * bounce_intensity, - bounce_intensity, bounce_intensity)
	if no_interpolation:
		camera_offset.y = bounce_target
	else:
		camera_offset.y = lerp(camera_offset.y, bounce_target, sway_lerp * delta)

	prev_horizontal_velocity = horizontal_velocity


	transform.origin = base_transform.origin + camera_offset

	if smooth_rotation:
		rotation.y = lerp_angle(rotation.y, target_yaw, rotation_lerp * delta)
		rotation.x = lerp(rotation.x, target_pitch, rotation_lerp * delta)

func apply_tilt(amount: float):
	tilt_target = clamp(amount, - max_tilt, max_tilt)


func _apply_settings() -> void :
	_load_sensitivity()
	_load_camera_view()
	_load_camera_mode()
	_load_camera_distance()
	_load_camera_fov()

func _refresh_camera_base() -> void :
	if not camera_node:
		return
	base_camera_local_origin = camera_node.transform.origin
	base_camera_distance = maxf(base_camera_local_origin.length(), 0.001)
	base_camera_fov = camera_node.fov

func _input(event):
	if get_tree().paused:
		return
	if event is InputEventMouseMotion:
		_apply_look_delta(event.relative)
		get_viewport().set_input_as_handled()

func _unhandled_input(event):
	if get_tree().paused:
		return
	if event is InputEventScreenTouch:
		var screen_touch: = event as InputEventScreenTouch
		if screen_touch.pressed:
			if touch_look_index == -1 and _is_in_touch_look_area(screen_touch.position):
				touch_look_index = screen_touch.index
				get_viewport().set_input_as_handled()
		elif screen_touch.index == touch_look_index:
			touch_look_index = -1
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		var screen_drag: = event as InputEventScreenDrag
		if screen_drag.index == touch_look_index:
			_apply_look_delta(screen_drag.relative * touch_sensitivity_multiplier)
			get_viewport().set_input_as_handled()

func _is_in_touch_look_area(touch_position: Vector2) -> bool:
	if _is_in_joystick_area(touch_position):
		return false
	return touch_position.x >= get_viewport().get_visible_rect().size.x * touch_look_area_start_ratio

func _is_in_joystick_area(touch_position: Vector2) -> bool:
	return mobile_joystick != null and mobile_joystick.get_global_rect().has_point(touch_position)

func _apply_look_delta(delta: Vector2) -> void :
	if smooth_rotation:
		target_yaw -= delta.x * sensitivity
		target_pitch -= delta.y * sensitivity
		target_pitch = clamp(target_pitch, deg_to_rad(min_pitch), deg_to_rad(max_pitch))
	else:
		rotate_y( - delta.x * sensitivity)
		pitch -= delta.y * sensitivity
		pitch = clamp(pitch, deg_to_rad(min_pitch), deg_to_rad(max_pitch))
		rotation.x = pitch

func _load_sensitivity() -> void :
	var cfg: = ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		var v = cfg.get_value(SETTINGS_SECTION, "sensitivity", 50)
		var t = clamp(float(v) / 100.0, 0.0, 1.0)
		sensitivity = lerp(SENS_MIN, SENS_MAX, t)

func _load_camera_mode() -> void :
	var cfg: = ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		_apply_camera_mode("static")
		return
	var raw_mode = cfg.get_value(SETTINGS_SECTION, "camera_mode", "static")
	var mode_key: = ""
	if typeof(raw_mode) == TYPE_INT:
		var idx: = int(raw_mode)
		if idx >= 0 and idx < CAMERA_MODE_KEYS.size():
			mode_key = CAMERA_MODE_KEYS[idx]
	else:
		mode_key = str(raw_mode)
	if CAMERA_MODE_KEYS.find(mode_key) < 0:
		mode_key = "static"
	_apply_camera_mode(mode_key)

func _load_camera_view() -> void :
	var cfg: = ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		_apply_camera_view("third")
		return
	var raw_view = cfg.get_value(SETTINGS_SECTION, "camera_view", "third")
	var view_key: = ""
	if typeof(raw_view) == TYPE_INT:
		var idx: = int(raw_view)
		if idx >= 0 and idx < CAMERA_VIEW_KEYS.size():
			view_key = CAMERA_VIEW_KEYS[idx]
	else:
		view_key = str(raw_view)
	if CAMERA_VIEW_KEYS.find(view_key) < 0:
		view_key = "third"
	_apply_camera_view(view_key)

func _load_camera_distance() -> void :
	var cfg: = ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		camera_distance_scale = 1.0
		_apply_camera_distance()
		return
	var v = float(cfg.get_value(SETTINGS_SECTION, "camera_distance", 100))
	v = clamp(v, CAMERA_DIST_MIN, CAMERA_DIST_MAX)
	camera_distance_scale = v / 100.0
	_apply_camera_distance()

func _load_camera_fov() -> void :
	if not camera_node:
		return
	var cfg: = ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		camera_node.fov = base_camera_fov
		return
	var v = float(cfg.get_value(SETTINGS_SECTION, "camera_fov", base_camera_fov))
	camera_node.fov = clamp(v, CAMERA_FOV_MIN, CAMERA_FOV_MAX)

func _apply_camera_distance() -> void :
	if not camera_node:
		return
	var origin = mode_camera_origin
	if origin.length() < 0.0001:
		origin = base_camera_local_origin
	camera_node.transform.origin = origin * camera_distance_scale

func _apply_camera_mode(mode_key: String) -> void :
	camera_mode = mode_key
	match mode_key:
		"standard":
			max_tilt = base_max_tilt
			tilt_speed = base_tilt_speed
			sway_intensity = base_sway_intensity
			bounce_intensity = base_bounce_intensity
			sway_lerp = base_sway_lerp
			smooth_rotation = false
			rotation_lerp = 10.0
			use_camera_space_movement = false
			no_interpolation = false
			mode_camera_origin = base_camera_local_origin
		"smooth":
			max_tilt = base_max_tilt * 0.4
			tilt_speed = base_tilt_speed * 0.6
			sway_intensity = base_sway_intensity * 0.35
			bounce_intensity = base_bounce_intensity * 0.25
			sway_lerp = base_sway_lerp * 0.5
			smooth_rotation = true
			rotation_lerp = 5.0
			use_camera_space_movement = true
			no_interpolation = false
			mode_camera_origin = base_camera_local_origin + shoulder_offset * 0.7
		"comfort_plus":
			max_tilt = base_max_tilt * 0.2
			tilt_speed = base_tilt_speed * 0.5
			sway_intensity = base_sway_intensity * 0.2
			bounce_intensity = base_bounce_intensity * 0.15
			sway_lerp = base_sway_lerp * 0.45
			smooth_rotation = true
			rotation_lerp = 3.5
			use_camera_space_movement = true
			no_interpolation = false
			mode_camera_origin = base_camera_local_origin + shoulder_offset * 0.6
		"game":
			max_tilt = base_max_tilt * 0.9
			tilt_speed = base_tilt_speed * 1.0
			sway_intensity = base_sway_intensity * 0.6
			bounce_intensity = base_bounce_intensity * 0.5
			sway_lerp = base_sway_lerp * 0.9
			smooth_rotation = true
			rotation_lerp = 14.0
			use_camera_space_movement = true
			no_interpolation = false
			mode_camera_origin = base_camera_local_origin + shoulder_offset
		"static":
			max_tilt = 0.0
			tilt_speed = 0.0
			sway_intensity = 0.0
			bounce_intensity = 0.0
			sway_lerp = 0.0
			smooth_rotation = false
			rotation_lerp = 10.0
			use_camera_space_movement = false
			no_interpolation = true
			current_tilt = 0.0
			tilt_target = 0.0
			camera_offset = Vector3.ZERO
			rotation.z = 0.0
			transform.origin = base_transform.origin
			mode_camera_origin = base_camera_local_origin
	_apply_camera_distance()

func _apply_camera_view(view_key: String) -> void :
	camera_view = view_key
	var use_fp: = view_key == "first" and camera_node_fp != null
	if use_fp:
		camera_node = camera_node_fp
		camera_node_fp.current = true
		if camera_node_tp:
			camera_node_tp.current = false
	else:
		camera_node = camera_node_tp
		if camera_node_tp:
			camera_node_tp.current = true
		if camera_node_fp:
			camera_node_fp.current = false
	_refresh_camera_base()
	if smooth_rotation:
		target_yaw = rotation.y
		target_pitch = rotation.x
