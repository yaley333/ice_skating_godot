extends CharacterBody3D


const MIN_SPEED = 10.0
const MAX_SPEED = 26.0
const ACCELERATION_RATE = 1.5
const FRICTION = 0.32
const JUMP_VELOCITY = 4.5
var GRAVITY = ProjectSettings.get_setting("physics/3d/default_gravity")

const SETTINGS_PATH: = "user://settings.cfg"
const SETTINGS_SECTION: = "settings"
const DEFAULT_MUSIC: = 70
const MUSIC_VOL_MIN_DB: = -30.0
const MUSIC_VOL_MAX_DB: = 0.0
const VOL_MIN_DB: = -80.0
const VOL_MAX_DB: = 0.0
const PAUSE_MENU_SCENE: = preload("res://ui/pause_menu.tscn")


@export var skate_mark_scene: PackedScene
@export var left_skate_offset: = 0.23
@export var right_skate_offset: = 0.18
@export var mark_height_offset: = -0.05
@export var mark_spacing: = 0.12
@export var turn_density: = 1.8

var distance_accum_left: = 0.0
var distance_accum_right: = 0.0
var last_move_dir: = Vector3.FORWARD


@export var slide_volume_max: float = -20.0
@export var slide_volume_min: float = -34.0
@export var slide_pitch_min: float = 0.75
@export var slide_pitch_max: float = 1.15
@export var slide_fade_speed: float = 3.5
@export var step_tail_time: float = 0.9
@export var step_interval_fallback: float = 0.99
@export var step_fade_time: float = 0.45
@export var step_volume_min_db: float = -40.0
@export var step_pitch_random_min: float = 0.9
@export var step_pitch_random_max: float = 2.9


@onready var camera_tp: Camera3D = $Head / Camera3D
@onready var camera_fp: Camera3D = get_node_or_null("Head/Camera3D2")
@onready var model = $girl
@onready var anim: AnimationPlayer = $girl / AnimationPlayer
@onready var skate_step_sound: AudioStreamPlayer3D = $IceScatingSound
@onready var slide_sound: AudioStreamPlayer3D = $IceSlideSound
@onready var music_player: AudioStreamPlayer2D = $Music


var step_sounds: Array[AudioStream] = [
	preload("res://sounds/ice/glide_on_ice1.mp3"), 
]
var step_rng: = RandomNumberGenerator.new()
var step_pitch_scales: Array[float] = [
	1.0, 
]


var current_speed: float = MIN_SPEED
var last_step_time: = -1.0
var last_step_index: = -1
var step_tail_timer: float = 0.0
var tail_step_timer: float = 0.0
var step_base_volume_db: float = 0.0
var step_fade_timer: float = 0.0
var prev_anim_time: = -1.0
var step_times: = [0.0, 1.1]
var last_anim_name: = ""
var pause_menu: Control = null
var sfx_muted: = false
var sfx_db: = 0.0
var was_paused: = false
var base_anim_speed: = 1.0

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("player")
	step_rng.randomize()
	if skate_step_sound:
		step_base_volume_db = skate_step_sound.volume_db
	if anim:
		base_anim_speed = anim.speed_scale
	_apply_volume_settings()
	_apply_music_settings()


func _physics_process(delta):
	if get_tree().paused:
		if not was_paused:
			_set_pause_state(true)
			was_paused = true
		return
	if was_paused:
		_set_pause_state(false)
		was_paused = false

	var sfx_blocked: = _is_settings_open() or _is_pause_menu_open()
	if sfx_blocked:
		if skate_step_sound and skate_step_sound.playing:
			skate_step_sound.stop()
		if slide_sound and slide_sound.playing:
			slide_sound.stop()

	if not is_on_floor():
		velocity.y -= GRAVITY * delta


	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY


	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var cam = _get_active_camera()
	if not cam:
		return
	var cam_basis = cam.global_transform.basis
	var forward = - cam_basis.z
	var right = cam_basis.x
	forward.y = 0
	right.y = 0
	forward = forward.normalized()
	right = right.normalized()
	var direction = (right * input_dir.x - forward * input_dir.y)


	if direction.length() > 0:
		direction = direction.normalized()
		current_speed += (MAX_SPEED - current_speed) * ACCELERATION_RATE * delta
		current_speed = clamp(current_speed, MIN_SPEED, MAX_SPEED)

		var target_velocity = direction * current_speed
		velocity.x = lerp(velocity.x, target_velocity.x, 0.08)
		velocity.z = lerp(velocity.z, target_velocity.z, 0.08)
	else:
		current_speed = MIN_SPEED
		velocity.x = lerp(velocity.x, 0.0, FRICTION * delta)
		velocity.z = lerp(velocity.z, 0.0, FRICTION * delta)


	var horizontal_velocity = Vector3(velocity.x, 0, velocity.z)
	if horizontal_velocity.length() > 0.1:
		var target_yaw = atan2(horizontal_velocity.x, horizontal_velocity.z)
		model.rotation.y = lerp_angle(model.rotation.y, target_yaw, 0.15)


	if input_dir.length() > 0:
		if anim.current_animation != "run":
			anim.play("run", 0.2)
	else:
		if anim.current_animation != "idle":
			anim.play("idle", 0.3)


	var horizontal_speed = Vector2(velocity.x, velocity.z).length()
	if (sfx_muted or sfx_blocked) and skate_step_sound and skate_step_sound.playing:
		skate_step_sound.stop()
	if skate_step_sound and anim.current_animation == "run":
		step_tail_timer = 0.0
		step_fade_timer = 0.0
		skate_step_sound.volume_db = step_base_volume_db
		var t = anim.current_animation_position
		var anim_len = maxf(anim.current_animation_length, 0.001)
		if last_anim_name != "run":

			prev_anim_time = t - delta
		if prev_anim_time < 0.0:
			prev_anim_time = t - delta

		var chosen_index: = -1
		var chosen_time: = -1.0
		var has_head: = false
		for i in range(step_times.size()):
			var st: float = step_times[i]
			if st < 0.0 or st > anim_len:
				continue
			var crossed: = false
			if t >= prev_anim_time:
				crossed = (st > prev_anim_time and st <= t)
			else:

				crossed = (st > prev_anim_time and st <= anim_len) or (st >= 0.0 and st <= t)
				if crossed and st <= t:
					has_head = true
			if crossed and i != last_step_index:
				if t >= prev_anim_time:
					if st > chosen_time:
						chosen_time = st
						chosen_index = i
				else:

					if st <= t:
						if not has_head or st > chosen_time:
							chosen_time = st
							chosen_index = i
							has_head = true
					elif not has_head and st > chosen_time:
						chosen_time = st
						chosen_index = i

		if chosen_index != -1:
			if step_sounds.size() > 0:
				var idx: = step_rng.randi_range(0, step_sounds.size() - 1)
				skate_step_sound.stream = step_sounds[idx]
				var base_pitch: = 1.0
				if idx < step_pitch_scales.size():
					base_pitch = step_pitch_scales[idx]
				skate_step_sound.pitch_scale = base_pitch * step_rng.randf_range(step_pitch_random_min, step_pitch_random_max)
			if not sfx_muted and not sfx_blocked:
				skate_step_sound.play()
			last_step_time = t
			last_step_index = chosen_index

		prev_anim_time = t
	else:
		last_step_time = -1.0
		last_step_index = -1
		prev_anim_time = -1.0
		step_tail_timer += delta
		if step_tail_timer <= step_tail_time and horizontal_speed > 0.3 and skate_step_sound:
			var step_interval: float = step_interval_fallback
			tail_step_timer += delta
			if tail_step_timer >= step_interval:
				tail_step_timer = 0.0
				if step_sounds.size() > 0:
					var idx: = step_rng.randi_range(0, step_sounds.size() - 1)
					skate_step_sound.stream = step_sounds[idx]
					var base_pitch: = 1.0
					if idx < step_pitch_scales.size():
						base_pitch = step_pitch_scales[idx]
					skate_step_sound.pitch_scale = base_pitch * step_rng.randf_range(step_pitch_random_min, step_pitch_random_max)
				if not sfx_muted and not sfx_blocked:
					skate_step_sound.play()
		else:
			tail_step_timer = 0.0
			if skate_step_sound and skate_step_sound.playing:
				step_fade_timer += delta
				var t_fade: float = clamp(step_fade_timer / maxf(step_fade_time, 0.01), 0.0, 1.0)
				skate_step_sound.volume_db = lerp(step_base_volume_db, step_volume_min_db, t_fade)
				if t_fade >= 1.0:
					skate_step_sound.stop()
	last_anim_name = anim.current_animation


	var is_sliding = input_dir.length() == 0 and horizontal_speed > 0.3

	if slide_sound:
		if sfx_muted or sfx_blocked:
			if slide_sound.playing:
				slide_sound.stop()
		else:
			if is_sliding:
				if not slide_sound.playing:
					slide_sound.play()
				var t_speed = clamp(horizontal_speed / MAX_SPEED, 0.0, 1.0)
				var base_db = lerp(slide_volume_min, slide_volume_max, t_speed)
				var target_db = base_db + (sfx_db - VOL_MAX_DB) + 30.0
				slide_sound.volume_db = lerp(slide_sound.volume_db, target_db, slide_fade_speed * delta)
				slide_sound.pitch_scale = lerp(slide_sound.pitch_scale, lerp(slide_pitch_min, slide_pitch_max, t_speed), slide_fade_speed * delta)
			else:
				var target_db = slide_volume_min + (sfx_db - VOL_MAX_DB) + 30.0
				slide_sound.volume_db = lerp(slide_sound.volume_db, target_db, slide_fade_speed * delta)
				if slide_sound.volume_db < target_db + 1.0:
					slide_sound.stop()


	spawn_skate_marks(delta)


	move_and_slide()


func get_active_skate():
	if anim.current_animation != "run":
		return "both"

	var t = anim.current_animation_position
	var length = anim.current_animation_length
	var phase = fmod(t, length) / length

	if phase < 0.5:
		return "left"
	else:
		return "right"


func spawn_skate_marks(delta):
	if not is_on_floor():
		return

	var horizontal_velocity = Vector3(velocity.x, 0, velocity.z)
	var speed = horizontal_velocity.length()
	if speed < 0.5:
		return

	var move_dir = horizontal_velocity.normalized()
	var right_vec = move_dir.cross(Vector3.UP).normalized()
	var base_rot = Basis().looking_at(move_dir, Vector3.UP)
	var skate_rot = base_rot.rotated(Vector3.UP, deg_to_rad(90))
	var world = get_tree().current_scene

	var active_skate = get_active_skate()
	var turn_amount = rad_to_deg(acos(clamp(last_move_dir.dot(move_dir), -1.0, 1.0)))
	var dynamic_spacing = mark_spacing / (1.0 + turn_amount * 0.02 * turn_density)


	if active_skate == "left" or active_skate == "both":
		distance_accum_left += speed * delta
		if distance_accum_left >= dynamic_spacing:
			distance_accum_left = 0.0
			var left_mark = skate_mark_scene.instantiate()
			world.add_child(left_mark)
			left_mark.global_transform = Transform3D(
				skate_rot, 
				global_transform.origin - right_vec * left_skate_offset + Vector3(0, mark_height_offset, 0)
			)


	if active_skate == "right" or active_skate == "both":
		distance_accum_right += speed * delta
		if distance_accum_right >= dynamic_spacing:
			distance_accum_right = 0.0
			var right_mark = skate_mark_scene.instantiate()
			world.add_child(right_mark)
			right_mark.global_transform = Transform3D(
				skate_rot, 
				global_transform.origin + right_vec * right_skate_offset + Vector3(0, mark_height_offset, 0)
			)

	last_move_dir = move_dir

func _apply_volume_settings() -> void :
	var cfg: = ConfigFile.new()
	var sfx_v: = 70
	if cfg.load(SETTINGS_PATH) == OK:
		sfx_v = int(cfg.get_value(SETTINGS_SECTION, "sfx_volume", 70))
	sfx_muted = sfx_v <= 0
	sfx_db = _percent_to_db(sfx_v)
	step_base_volume_db = sfx_db
	if skate_step_sound:
		skate_step_sound.volume_db = sfx_db
		if (sfx_muted or _is_settings_open() or _is_pause_menu_open()) and skate_step_sound.playing:
			skate_step_sound.stop()
	if slide_sound:
		slide_sound.volume_db = sfx_db
		if (sfx_muted or _is_settings_open() or _is_pause_menu_open()) and slide_sound.playing:
			slide_sound.stop()

func _percent_to_db(v) -> float:
	var t = clamp(float(v) / 100.0, 0.0, 1.0)
	return lerp(VOL_MIN_DB, VOL_MAX_DB, t)

func _unhandled_input(event):
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if get_tree().get_nodes_in_group("settings_menu").size() > 0:
			return
		_toggle_pause_menu()

func _toggle_pause_menu() -> void :
	if get_tree().paused:
		if pause_menu:
			pause_menu.queue_free()
			pause_menu = null
		get_tree().paused = false
		_set_pause_state(false)
		was_paused = false
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		return
	pause_menu = PAUSE_MENU_SCENE.instantiate()
	get_tree().current_scene.add_child(pause_menu)
	get_tree().paused = true
	_set_pause_state(true)
	was_paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func toggle_pause_menu() -> void :
	_toggle_pause_menu()

func _apply_settings() -> void :
	_apply_volume_settings()
	_apply_music_settings()

func _is_settings_open() -> bool:
	return get_tree().get_first_node_in_group("settings_menu") != null

func _is_pause_menu_open() -> bool:
	return pause_menu != null or get_tree().paused

func _set_pause_state(paused: bool) -> void :
	if not anim:
		return
	anim.speed_scale = 0.0 if paused else base_anim_speed
	if paused:
		if skate_step_sound and skate_step_sound.playing:
			skate_step_sound.stop()
		if slide_sound and slide_sound.playing:
			slide_sound.stop()

func _apply_music_settings() -> void :
	if not music_player:
		return
	var cfg: = ConfigFile.new()
	var music_v: = DEFAULT_MUSIC
	var resume_pending: = false
	var resume_pos: = 0.0
	if cfg.load(SETTINGS_PATH) == OK:
		music_v = int(cfg.get_value(SETTINGS_SECTION, "music_volume", DEFAULT_MUSIC))
		resume_pending = bool(cfg.get_value(SETTINGS_SECTION, "music_resume_pending", false))
		resume_pos = float(cfg.get_value(SETTINGS_SECTION, "music_resume_pos", 0.0))
	music_player.volume_db = _percent_to_music_db(music_v)
	if resume_pending:
		if music_player.playing:
			music_player.stop()
		music_player.play(maxf(resume_pos, 0.0))
		cfg.set_value(SETTINGS_SECTION, "music_resume_pending", false)
		cfg.save(SETTINGS_PATH)

func _percent_to_music_db(v: int) -> float:
	var t = clamp(float(v) / 100.0, 0.0, 1.0)
	var curved = sqrt(t)
	return lerp(MUSIC_VOL_MIN_DB, MUSIC_VOL_MAX_DB, curved)

func _get_active_camera() -> Camera3D:
	if camera_fp and camera_fp.current:
		return camera_fp
	return camera_tp
