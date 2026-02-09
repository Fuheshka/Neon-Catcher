extends Node2D
class_name Spawner

"""Scenes that can be spawned; each should use FallingObject with configured exports."""
@export var spawnable_scenes: Array[PackedScene] = []

"""Seconds between spawns."""
@export var spawn_interval: float = 1.0

"""Optional weights matching spawnable_scenes; higher = more frequent."""
@export var spawn_weights: Array = []

"""Horizontal padding from viewport edges for spawn positions."""
@export var safe_margin: float = 60.0

"""Number of fixed lanes across the playfield (minimum enforced at 4)."""
@export var lane_count: int = 4

"""Vertical gap (pixels) required before spawning the next wave."""
@export var vertical_buffer: float = 150.0

"""Minimum objects per wave."""
@export var spawn_per_wave_min: int = 1

"""Maximum objects per wave (never exceed 2 lanes)."""
@export var spawn_per_wave_max: int = 2

"""Random Y jitter applied to each spawn to avoid straight lines."""
@export var spawn_y_jitter: float = 50.0

var _spawn_timer: Timer
var _difficulty_timer: Timer
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _active: bool = true
var _difficulty_level: int = 0
@onready var _events: Node = get_node("/root/Events")


func _ready() -> void:
	_rng.randomize()

	_spawn_timer = Timer.new()
	_spawn_timer.one_shot = false
	_spawn_timer.wait_time = spawn_interval
	add_child(_spawn_timer)
	_spawn_timer.timeout.connect(_on_spawn_timeout)
	_spawn_timer.start()

	_difficulty_timer = Timer.new()
	_difficulty_timer.one_shot = false
	_difficulty_timer.wait_time = 10.0
	_difficulty_timer.autostart = true
	add_child(_difficulty_timer)
	_difficulty_timer.timeout.connect(_on_difficulty_timeout)
	_difficulty_timer.start()

	_events.connect("game_over", _on_game_over)


func _on_spawn_timeout() -> void:
	if not _active:
		return
	if spawnable_scenes.is_empty():
		return
	if not _has_vertical_buffer():
		return

	var lanes: Array[float] = _build_lane_positions()
	if lanes.size() < 2:
		return

	var spawn_count: int = _determine_wave_spawn_count(lanes.size())
	var lane_indices: Array = _pick_lanes_for_wave(lanes.size(), spawn_count)

	for lane_index in lane_indices:
		var lane_x: float = lanes[lane_index]
		var pick: PackedScene = _pick_scene_weighted()
		if pick == null:
			continue

		var instance: Node2D = pick.instantiate() as Node2D
		if instance == null:
			continue

		var y_offset: float = _rng.randf_range(-spawn_y_jitter, spawn_y_jitter)
		instance.global_position = Vector2(lane_x, global_position.y + y_offset)
		(get_parent() as Node).add_child(instance)


func _on_difficulty_timeout() -> void:
	if not _active:
		return
	if not is_instance_valid(_spawn_timer):
		return
	_spawn_timer.wait_time = max(0.3, _spawn_timer.wait_time - 0.1)
	_difficulty_level += 1
	Events.emit_difficulty_increased(_difficulty_level)
	print("Difficulty Increased!")


func _determine_wave_spawn_count(total_lanes: int) -> int:
	var min_spawn: int = clamp(spawn_per_wave_min, 1, total_lanes)
	var max_spawn: int = clamp(spawn_per_wave_max, min_spawn, min(total_lanes, 2))
	return _rng.randi_range(min_spawn, max_spawn)


func _build_lane_positions() -> Array[float]:
	var viewport_width: float = get_viewport_rect().size.x
	var margin: float = max(0.0, safe_margin)
	var safe_width: float = max(0.0, viewport_width - (margin * 2.0))
	var count: int = max(4, lane_count)
	if safe_width <= 0.0:
		return []
	var step: float = safe_width / float(count)
	var lanes: Array[float] = []
	for i in range(count):
		lanes.append(margin + (step * 0.5) + (step * float(i)))
	return lanes


func _pick_lanes_for_wave(total_lanes: int, spawn_count: int) -> Array:
	spawn_count = min(spawn_count, min(2, total_lanes))

	# Single spawn is always safe; pick any lane.
	if spawn_count <= 1:
		return [_rng.randi_range(0, total_lanes - 1)]

	# For two spawns, enforce non-adjacent lanes (prevents merge into one blob).
	var combos: Array = []
	for i in range(total_lanes):
		for j in range(i + 1, total_lanes):
			if abs(i - j) >= 2:
				var pair: Array = [i, j]
				combos.append(pair)

	if combos.is_empty():
		# Fallback: spawn a single object to preserve space.
		return [_rng.randi_range(0, total_lanes - 1)]

	var chosen_pair: Array = combos[_rng.randi_range(0, combos.size() - 1)]
	return chosen_pair


func _pick_scene_weighted() -> PackedScene:
	if spawnable_scenes.is_empty():
		return null
	var weights: Array = _normalized_weights()
	var total: float = 0.0
	for w in weights:
		total += float(w)
	if total <= 0.0:
		return spawnable_scenes[_rng.randi_range(0, spawnable_scenes.size() - 1)]
	var roll: float = _rng.randf_range(0.0, total)
	var accum: float = 0.0
	for i in range(spawnable_scenes.size()):
		accum += float(weights[i])
		if roll <= accum:
			return spawnable_scenes[i]
	return spawnable_scenes.back()


func _normalized_weights() -> Array:
	var weights: Array = []
	if spawn_weights.size() != spawnable_scenes.size():
		weights.resize(spawnable_scenes.size())
		for i in range(weights.size()):
			weights[i] = 1.0
		return weights
	for w in spawn_weights:
		weights.append(max(0.0, float(w)))
	return weights


func _has_vertical_buffer() -> bool:
	if vertical_buffer <= 0.0:
		return true
	var highest_y: float = _get_highest_falling_object_y()
	if highest_y == INF:
		return true
	var gate_y: float = (global_position.y - spawn_y_jitter) + vertical_buffer
	return highest_y >= gate_y


func _get_highest_falling_object_y() -> float:
	var parent_node: Node = get_parent()
	if parent_node == null:
		return INF
	var min_y: float = INF
	for child in parent_node.get_children():
		if child is FallingObject:
			var obj: FallingObject = child as FallingObject
			if obj.is_queued_for_deletion():
				continue
			min_y = min(min_y, obj.global_position.y)
	return min_y


func _on_game_over() -> void:
	_active = false
	if is_instance_valid(_spawn_timer):
		_spawn_timer.stop()
	if is_instance_valid(_difficulty_timer):
		_difficulty_timer.stop()
