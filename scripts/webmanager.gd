extends CanvasLayer
class_name WebManager

signal start_game_requested

@export var overlay: Control
@export var start_button: Button

var _activated: bool = false

func _ready() -> void:
	_check_renderer()
	if not OS.has_feature("web"):
		_hide_overlay()
		return
	_pause_game()
	_connect_inputs()

func _connect_inputs() -> void:
	if is_instance_valid(start_button) and not start_button.pressed.is_connected(_on_user_activation):
		start_button.pressed.connect(_on_user_activation)
	if is_instance_valid(overlay) and not overlay.gui_input.is_connected(_on_overlay_gui_input):
		overlay.gui_input.connect(_on_overlay_gui_input)

func _on_overlay_gui_input(event: InputEvent) -> void:
	if _activated:
		return
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		_on_user_activation()
	if event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed:
		_on_user_activation()

func _on_user_activation() -> void:
	if _activated:
		return
	_activated = true
	_unmute_audio()
	get_tree().paused = false
	_hide_overlay()
	start_game_requested.emit()

func _pause_game() -> void:
	get_tree().paused = true
	_show_overlay()

func _show_overlay() -> void:
	if is_instance_valid(overlay):
		overlay.visible = true
		overlay.mouse_filter = Control.MOUSE_FILTER_STOP

func _hide_overlay() -> void:
	if is_instance_valid(overlay):
		overlay.visible = false
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _unmute_audio() -> void:
	AudioServer.set_bus_mute(0, false)
	AudioServer.set_bus_volume_db(0, 0.0)

func _check_renderer() -> void:
	var method: String = str(ProjectSettings.get_setting("rendering/renderer/rendering_method", ""))
	if method != "gl_compatibility":
		push_warning("Для Web нужен Compatibility renderer. Сейчас: %s" % method)
