extends Node

## Укажи путь к своему .ogg треку здесь, если экспорты не работают:
const MUSIC_FILE_PATH: String = "res://assets/sounds/music.ogg"  # <- ИЗМЕНИ ЭТОТ ПУТЬ

@export var music_stream: AudioStream
@export_file("*.ogg", "*.mp3", "*.wav") var music_path: String = ""
@export var fade_in_time: float = 2.0
@export var fade_out_time: float = 1.0
@export var max_pitch: float = 1.25
@export var pitch_step: float = 0.03
@export var pitch_tween_time: float = 0.25
@export var start_volume_db: float = 0.0
@export var muted_volume_db: float = -35.0
@export var pause_volume_db: float = -8.0
@export var pause_lowpass_cutoff_hz: float = 900.0
@export var normal_lowpass_cutoff_hz: float = 20500.0

var _player: AudioStreamPlayer
var _fade_tween: Tween
var _pitch_tween: Tween
var _audio_unlocked: bool = false
var _pending_start: bool = false
var _target_pitch: float = 1.0
var _lowpass: AudioEffectLowPassFilter
var _bus_index: int = -1
var _last_paused: bool = false
var _music_started: bool = false


func _ready() -> void:
	print("[MusicManager] Initializing...")
	# Пробуем загрузить в порядке приоритета:
	# 1. music_stream (если назначен через инспектор)
	# 2. music_path (если указан)
	# 3. MUSIC_FILE_PATH (константа в коде)
	if music_stream == null and music_path != "":
		print("[MusicManager] Loading music from music_path: ", music_path)
		music_stream = ResourceLoader.load(music_path) as AudioStream
	if music_stream == null and MUSIC_FILE_PATH != "":
		print("[MusicManager] Loading music from MUSIC_FILE_PATH: ", MUSIC_FILE_PATH)
		if ResourceLoader.exists(MUSIC_FILE_PATH):
			music_stream = ResourceLoader.load(MUSIC_FILE_PATH) as AudioStream
		else:
			print("[MusicManager] ERROR: File not found at ", MUSIC_FILE_PATH)
	if music_stream != null:
		print("[MusicManager] Music stream loaded: ", music_stream.resource_path if music_stream.resource_path else "(generated)")
	else:
		print("[MusicManager] WARNING: No music stream assigned!")
		print("[MusicManager] HELP: Set MUSIC_FILE_PATH constant in MusicManager.gd to your .ogg file path")
	_player = AudioStreamPlayer.new()
	_player.name = "MusicPlayer"
	_player.bus = "Master"
	_player.volume_db = muted_volume_db
	_player.pitch_scale = 1.0
	_player.autoplay = false
	_player.process_mode = Node.PROCESS_MODE_ALWAYS
	_player.stream = music_stream
	add_child(_player)
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(true)
	_loop_stream_if_supported()
	_cache_bus_index()
	_ensure_lowpass_effect()
	Events.game_over.connect(_on_game_over)
	Events.web_ready.connect(_on_web_ready)
	Events.difficulty_increased.connect(_on_difficulty_increased)
	_audio_unlocked = not OS.has_feature("web")
	_last_paused = get_tree().paused


func start_music() -> void:
	if _music_started:
		print("[MusicManager] Music already started - ignoring")
		return
	print("[MusicManager] start_music() called")
	if _player == null:
		print("[MusicManager] ERROR: Player is null")
		return
	if _player.stream == null and music_stream != null:
		print("[MusicManager] Assigning music_stream to player")
		_player.stream = music_stream
	if _player.stream == null and music_path != "":
		print("[MusicManager] Loading stream from path")
		_player.stream = ResourceLoader.load(music_path) as AudioStream
	if _player.stream == null:
		print("[MusicManager] ERROR: No music stream - cannot play")
		return
	print("[MusicManager] Stream ready: ", _player.stream)
	_cache_bus_index()
	if OS.has_feature("web") and not _audio_unlocked:
		print("[MusicManager] Web build - waiting for user interaction")
		_pending_start = true
		return
	_pending_start = false
	if _fade_tween and _fade_tween.is_running():
		_fade_tween.kill()
	if _pitch_tween and _pitch_tween.is_running():
		_pitch_tween.kill()
	print("[MusicManager] Starting playback - bus:", _bus_index)
	if not _player.playing:
		_player.play()
		print("[MusicManager] Player.play() called - playing:", _player.playing)
	AudioServer.set_bus_mute(_bus_index, false)
	AudioServer.set_bus_volume_db(_bus_index, 0.0)
	_player.volume_db = muted_volume_db
	print("[MusicManager] Player volume:", _player.volume_db, " -> fading to:", start_volume_db)
	_set_pitch(1.0, 0.0)
	_fade_to(start_volume_db, fade_in_time)
	_music_started = true


func fade_out() -> void:
	if _player == null:
		return
	_pending_start = false
	_music_started = false
	if not _player.playing:
		return
	_fade_to(muted_volume_db, fade_out_time, true)


func update_pitch(difficulty_factor: float) -> void:
	if _player == null:
		return
	var pitch: float = 1.0 + ((max(difficulty_factor, 1.0) - 1.0) * (max_pitch - 1.0))
	_set_pitch(pitch, pitch_tween_time)


func _on_difficulty_increased(level: int) -> void:
	var target: float = 1.0 + (float(level) * pitch_step)
	_set_pitch(target, pitch_tween_time)


func _on_game_over() -> void:
	fade_out()


func _on_web_ready() -> void:
	print("[MusicManager] Web ready - unlocking audio")
	_audio_unlocked = true
	if _pending_start:
		start_music()


func _process(_delta: float) -> void:
	# React to pause toggles for audio filtering.
	var paused: bool = get_tree().paused
	if paused != _last_paused:
		_apply_pause_state(paused)
		_last_paused = paused


func _fade_to(target_db: float, duration: float, stop_when_done: bool = false) -> void:
	if _fade_tween and _fade_tween.is_running():
		_fade_tween.kill()
	if duration <= 0.0:
		_player.volume_db = target_db
		if stop_when_done:
			_player.stop()
		return
	_fade_tween = create_tween()
	_fade_tween.set_ignore_time_scale(true)
	_fade_tween.tween_property(_player, "volume_db", target_db, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if stop_when_done:
		_fade_tween.tween_callback(Callable(_player, "stop"))


func _set_pitch(target: float, duration: float) -> void:
	_target_pitch = clamp(target, 1.0, max_pitch)
	if _player == null:
		return
	if duration <= 0.0:
		_player.pitch_scale = _target_pitch
		return
	if _pitch_tween and _pitch_tween.is_running():
		_pitch_tween.kill()
	_pitch_tween = create_tween()
	_pitch_tween.set_ignore_time_scale(true)
	_pitch_tween.tween_property(_player, "pitch_scale", _target_pitch, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _cache_bus_index() -> void:
	_bus_index = AudioServer.get_bus_index(_player.bus)
	if _bus_index < 0:
		_bus_index = 0


func _ensure_lowpass_effect() -> void:
	if _bus_index < 0:
		_cache_bus_index()
	if _bus_index < 0:
		return
	for i in range(AudioServer.get_bus_effect_count(_bus_index)):
		var eff: AudioEffect = AudioServer.get_bus_effect(_bus_index, i)
		if eff is AudioEffectLowPassFilter:
			_lowpass = eff as AudioEffectLowPassFilter
			break
	if _lowpass == null:
		_lowpass = AudioEffectLowPassFilter.new()
		_lowpass.cutoff_hz = normal_lowpass_cutoff_hz
		AudioServer.add_bus_effect(_bus_index, _lowpass, -1)
	else:
		_lowpass.cutoff_hz = normal_lowpass_cutoff_hz


func _apply_pause_state(paused: bool) -> void:
	if _lowpass == null:
		return
	var target_cutoff: float = normal_lowpass_cutoff_hz
	if paused:
		target_cutoff = pause_lowpass_cutoff_hz
		_fade_to(pause_volume_db, 0.3)
	else:
		_fade_to(start_volume_db, 0.3)
	_lowpass.cutoff_hz = clamp(target_cutoff, 20.0, 22000.0)


func _ensure_playing() -> void:
	if _player == null or _player.stream == null:
		return
	if not _player.playing and not get_tree().paused:
		print("[MusicManager] Ensuring playback - restarting player")
		_player.play()
		_fade_to(start_volume_db, fade_in_time)


func _loop_stream_if_supported() -> void:
	if _player == null or _player.stream == null:
		print("[MusicManager] Cannot set loop - player or stream is null")
		return
	print("[MusicManager] Setting up loop for stream type: ", _player.stream.get_class())
	if _player.stream.has_method("set_loop"):
		_player.stream.call("set_loop", true)
		print("[MusicManager] Loop enabled via set_loop")
	elif _player.stream.has_method("set_loop_mode"):
		_player.stream.call("set_loop_mode", true)
		print("[MusicManager] Loop enabled via set_loop_mode")
	elif _player.stream.has_method("set_looping"):
		_player.stream.call("set_looping", true)
		print("[MusicManager] Loop enabled via set_looping")
	elif _player.stream.has_method("set_loop_enabled"):
		_player.stream.call("set_loop_enabled", true)
		print("[MusicManager] Loop enabled via set_loop_enabled")
	elif _player.stream.has_property("loop"):
		_player.stream.set("loop", true)
		print("[MusicManager] Loop enabled via loop property")
	else:
		print("[MusicManager] WARNING: Could not find loop method/property for this stream type")
