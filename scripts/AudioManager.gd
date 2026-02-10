extends Node
class_name AudioManager

"""Centralized audio handler reacting to global Events."""

@export var score_sound: AudioStream
@export var damage_sound: AudioStream
@export var game_over_sound: AudioStream
@export var combo_up_sound: AudioStream
@export var combo_break_sound: AudioStream

var _score_player: AudioStreamPlayer
var _damage_player: AudioStreamPlayer
var _game_over_player: AudioStreamPlayer
var _combo_player: AudioStreamPlayer
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

var _last_score: int = 0
var _last_health: int = 0
var _last_combo: float = 1.0
var _score_initialized: bool = false
var _health_initialized: bool = false
var _combo_initialized: bool = false


func _ready() -> void:
	_rng.randomize()
	_score_player = _make_player("ScorePlayer")
	_damage_player = _make_player("DamagePlayer")
	_game_over_player = _make_player("GameOverPlayer")
	_combo_player = _make_player("ComboPlayer")
	Events.score_updated.connect(_on_score_updated)
	Events.health_updated.connect(_on_health_updated)
	Events.game_over.connect(_on_game_over)
	Events.combo_changed.connect(_on_combo_changed)


func _on_score_updated(new_total: int) -> void:
	if _score_initialized and new_total > _last_score:
		# Увеличиваем пич в зависимости от комбо
		var pitch: float = _rng.randf_range(0.9, 1.1) + (_last_combo - 1.0) * 0.15
		_play_player(_score_player, score_sound, clamp(pitch, 0.8, 1.8))
	_last_score = new_total
	_score_initialized = true


func _on_health_updated(new_total: int) -> void:
	if _health_initialized and new_total < _last_health:
		_play_player(_damage_player, damage_sound)
	_last_health = new_total
	_health_initialized = true


func _on_game_over() -> void:
	_play_player(_game_over_player, game_over_sound)


func _on_combo_changed(new_combo: float) -> void:
	if _combo_initialized:
		if new_combo > _last_combo:
			# Комбо растёт
			var pitch: float = 1.0 + (new_combo - 1.0) * 0.25
			_play_player(_combo_player, combo_up_sound, clamp(pitch, 1.0, 2.0))
		elif new_combo < _last_combo:
			# Комбо сброшено
			_play_player(_combo_player, combo_break_sound, 0.9)
	_last_combo = new_combo
	_combo_initialized = true


func _make_player(player_name: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = player_name
	add_child(player)
	return player


func _play_player(player: AudioStreamPlayer, stream: AudioStream, pitch: float = 1.0) -> void:
	if stream == null:
		return
	player.stream = stream
	player.pitch_scale = pitch
	player.play()
