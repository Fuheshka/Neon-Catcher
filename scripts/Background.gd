extends ColorRect
class_name Background

@export var start_color: Color = Color(0.05, 0.08, 0.16, 1.0)
@export var end_color: Color = Color(0.4, 0.05, 0.07, 1.0)
@export var max_difficulty_steps: int = 10
@export var transition_duration: float = 1.4

@export var grid_scroll: Vector2 = Vector2(0.0, -0.35)
@export var grid_cell_size: Vector2 = Vector2(72.0, 72.0)
@export var grid_line_thickness: float = 0.06
@export var grid_color: Color = Color(0.0, 1.35, 1.1, 0.45)

@export var glitch_duration: float = 0.2
@export var glitch_magnitude: float = 0.35

@export var speed_line_spawn_interval: Vector2 = Vector2(0.35, 0.9)
@export var speed_line_speed_range: Vector2 = Vector2(820.0, 1400.0)
@export var speed_line_length_range: Vector2 = Vector2(160.0, 280.0)
@export var speed_line_width: float = 2.0
@export var speed_line_color: Color = Color(0.8, 1.2, 1.5, 0.35)
@export var enable_speed_lines: bool = false

const _GRID_SHADER: String = """
shader_type canvas_item;

uniform vec2 u_scroll_speed = vec2(0.0, -0.35);
uniform vec2 u_grid_size = vec2(72.0, 72.0);
uniform float u_line_thickness = 0.06;
uniform vec4 u_grid_color = vec4(0.0, 1.35, 1.1, 0.45);
uniform vec4 u_bg_color = vec4(0.05, 0.08, 0.16, 1.0);
uniform float u_time = 0.0;
uniform vec2 u_glitch_offset = vec2(0.0, 0.0);

void fragment() {
	vec2 uv = FRAGCOORD.xy / u_grid_size + (u_scroll_speed * u_time) + u_glitch_offset;
	vec2 cell = abs(fract(uv) - 0.5);
	float line_dist = max(cell.x, cell.y);
	float line = smoothstep(0.5, 0.5 - u_line_thickness, line_dist);
	vec4 grid = vec4(u_grid_color.rgb, u_grid_color.a * line);
	COLOR = mix(u_bg_color, grid, line);
}
"""

var _tween: Tween
var _shader_material: ShaderMaterial
var _time: float = 0.0
var _glitch_timer: float = 0.0
var _glitch_offset: Vector2 = Vector2.ZERO
var _speed_lines: Array = []
var _speed_line_cooldown: float = 0.0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	color = start_color
	_ensure_shader()
	set_process(true)
	Events.difficulty_increased.connect(_on_difficulty_increased)
	Events.game_over.connect(_on_game_over)
	Events.impact_occurred.connect(_on_impact_occurred)


func _process(delta: float) -> void:
	_time += delta
	_update_glitch(delta)
	_update_speed_lines(delta)
	if _shader_material:
		_shader_material.set_shader_parameter("u_time", _time)
		_shader_material.set_shader_parameter("u_scroll_speed", grid_scroll)
		_shader_material.set_shader_parameter("u_grid_size", grid_cell_size)
		_shader_material.set_shader_parameter("u_line_thickness", grid_line_thickness)
		_shader_material.set_shader_parameter("u_grid_color", grid_color)
		_shader_material.set_shader_parameter("u_bg_color", color)
		_shader_material.set_shader_parameter("u_glitch_offset", _glitch_offset)
	queue_redraw()


func _on_difficulty_increased(level: int) -> void:
	var t: float = clamp(float(level) / float(max_difficulty_steps), 0.0, 1.0)
	var target: Color = start_color.lerp(end_color, t)

	if _tween and _tween.is_running():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "color", target, transition_duration).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)


func _on_game_over() -> void:
	if _tween and _tween.is_running():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "color", start_color, transition_duration).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_glitch_timer = 0.0
	_glitch_offset = Vector2.ZERO
	if _shader_material:
		_shader_material.set_shader_parameter("u_glitch_offset", Vector2.ZERO)


func _ensure_shader() -> void:
	if material == null or not (material is ShaderMaterial):
		var shader: Shader = Shader.new()
		shader.code = _GRID_SHADER
		_shader_material = ShaderMaterial.new()
		_shader_material.shader = shader
		material = _shader_material
	else:
		_shader_material = material as ShaderMaterial

	_shader_material.set_shader_parameter("u_grid_size", grid_cell_size)
	_shader_material.set_shader_parameter("u_line_thickness", grid_line_thickness)
	_shader_material.set_shader_parameter("u_grid_color", grid_color)
	_shader_material.set_shader_parameter("u_bg_color", start_color)
	_shader_material.set_shader_parameter("u_scroll_speed", grid_scroll)
	_shader_material.set_shader_parameter("u_time", _time)
	_shader_material.set_shader_parameter("u_glitch_offset", _glitch_offset)


func _on_impact_occurred() -> void:
	_glitch_timer = glitch_duration


func _update_glitch(delta: float) -> void:
	if _glitch_timer > 0.0:
		_glitch_timer -= delta
		_glitch_offset = Vector2(_rng.randf_range(-glitch_magnitude, glitch_magnitude), _rng.randf_range(-glitch_magnitude, glitch_magnitude))
	else:
		_glitch_offset = Vector2.ZERO


func _update_speed_lines(delta: float) -> void:
	if not enable_speed_lines:
		_speed_lines.clear()
		return
	_speed_line_cooldown -= delta
	if _speed_line_cooldown <= 0.0:
		_spawn_speed_line()
		_speed_line_cooldown = _rng.randf_range(speed_line_spawn_interval.x, speed_line_spawn_interval.y)

	var bounds: Vector2 = _get_bounds_size()
	for i in range(_speed_lines.size() - 1, -1, -1):
		var line: Dictionary = _speed_lines[i]
		line["position"].y += line["speed"] * delta
		if line["position"].y - line["length"] > bounds.y + 48.0:
			_speed_lines.remove_at(i)


func _spawn_speed_line() -> void:
	var bounds: Vector2 = _get_bounds_size()
	if bounds == Vector2.ZERO:
		return
	var x: float = _rng.randf_range(0.0, bounds.x)
	var length: float = _rng.randf_range(speed_line_length_range.x, speed_line_length_range.y)
	var speed: float = _rng.randf_range(speed_line_speed_range.x, speed_line_speed_range.y)
	var line_color: Color = speed_line_color
	line_color.a = speed_line_color.a * _rng.randf_range(0.7, 1.1)
	var width: float = max(0.6, speed_line_width * _rng.randf_range(0.8, 1.2))
	_speed_lines.append({
		"position": Vector2(x, -length),
		"length": length,
		"speed": speed,
		"width": width,
		"color": line_color,
	})


func _draw() -> void:
	for line_dict in _speed_lines:
		var start: Vector2 = line_dict.get("position", Vector2.ZERO)
		var end: Vector2 = start + Vector2(0.0, line_dict.get("length", 0.0))
		var line_color: Color = line_dict.get("color", speed_line_color)
		var width: float = line_dict.get("width", speed_line_width)
		draw_line(start, end, line_color, width)


func _get_bounds_size() -> Vector2:
	var bounds: Vector2 = size
	if bounds == Vector2.ZERO:
		bounds = get_viewport_rect().size
	return bounds
