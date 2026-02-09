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

const _GRID_SHADER: String = """
shader_type canvas_item;

uniform vec2 u_scroll_speed = vec2(0.0, -0.35);
uniform vec2 u_grid_size = vec2(72.0, 72.0);
uniform float u_line_thickness = 0.06;
uniform vec4 u_grid_color = vec4(0.0, 1.35, 1.1, 0.45);
uniform vec4 u_bg_color = vec4(0.05, 0.08, 0.16, 1.0);
uniform float u_time = 0.0;

void fragment() {
	vec2 uv = FRAGCOORD.xy / u_grid_size + (u_scroll_speed * u_time);
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


func _ready() -> void:
	color = start_color
	_ensure_shader()
	set_process(true)
	Events.difficulty_increased.connect(_on_difficulty_increased)
	Events.game_over.connect(_on_game_over)


func _process(delta: float) -> void:
	_time += delta
	if _shader_material:
		_shader_material.set_shader_parameter("u_time", _time)
		_shader_material.set_shader_parameter("u_scroll_speed", grid_scroll)
		_shader_material.set_shader_parameter("u_grid_size", grid_cell_size)
		_shader_material.set_shader_parameter("u_line_thickness", grid_line_thickness)
		_shader_material.set_shader_parameter("u_grid_color", grid_color)
		_shader_material.set_shader_parameter("u_bg_color", color)


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
