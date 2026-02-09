extends TextureRect
class_name GridScroller

@export var scroll_speed: Vector2 = Vector2(0.0, -40.0)

var _uv_offset: Vector2 = Vector2.ZERO
var _texture_size: Vector2 = Vector2.ONE
var _shader_material: ShaderMaterial

const _SCROLL_SHADER: String = """
shader_type canvas_item;
uniform vec2 u_offset = vec2(0.0, 0.0);

void fragment() {
	vec2 uv = UV + u_offset;
	COLOR = texture(TEXTURE, uv);
}
"""

func _ready() -> void:
	set_process(true)
	_refresh_texture_size()
	_ensure_material()

func _process(delta: float) -> void:
	if texture == null or _shader_material == null:
		return

	_uv_offset += scroll_speed * delta
	# Use normalized offset (UV space) so wrapping works with tiled textures.
	var normalized_offset: Vector2 = Vector2.ZERO
	if _texture_size.x != 0.0:
		normalized_offset.x = _uv_offset.x / _texture_size.x
	if _texture_size.y != 0.0:
		normalized_offset.y = _uv_offset.y / _texture_size.y
	# Wrap to avoid large values.
	normalized_offset.x = fposmod(normalized_offset.x, 1.0)
	normalized_offset.y = fposmod(normalized_offset.y, 1.0)
	_shader_material.set_shader_parameter("u_offset", normalized_offset)

func _refresh_texture_size() -> void:
	_texture_size = texture.get_size() if texture != null else Vector2.ONE

func _ensure_material() -> void:
	if material == null or not (material is ShaderMaterial):
		var shader: Shader = Shader.new()
		shader.code = _SCROLL_SHADER
		_shader_material = ShaderMaterial.new()
		_shader_material.shader = shader
		material = _shader_material
	else:
		_shader_material = material as ShaderMaterial
	# Enable repeat so UV offset wraps visually when the texture import allows it.
	texture_repeat = TEXTURE_REPEAT_ENABLED
