extends CanvasLayer
class_name WebHelper

signal start_game_requested(base_url: String)

@export var overlay: Control
@export var start_button: Button
@export var spawner_path: NodePath = NodePath("../World/Spawner")

var base_url: String = ""
var _activated: bool = false


func _ready() -> void:
	base_url = _detect_base_url()
	_setup_resize_listener()
	if not OS.has_feature("web"):
		_hide_overlay()
		return
	_pause_for_user_activation()
	_connect_inputs()


func _detect_base_url() -> String:
	if not OS.has_feature("web"):
		return ""
	var result: Variant = JavaScriptBridge.eval(r"window.location.origin + window.location.pathname.replace(/\\/[^/]*$/, '/')")
	if typeof(result) == TYPE_STRING:
		return String(result)
	return ""


func _setup_resize_listener() -> void:
	var root_window: Window = get_tree().root
	if root_window and not root_window.size_changed.is_connected(_on_root_resized):
		root_window.size_changed.connect(_on_root_resized)
	_apply_content_scale()


func _on_root_resized() -> void:
	_apply_content_scale()


func _apply_content_scale() -> void:
	var root_window: Window = get_tree().root
	if root_window == null:
		return
	root_window.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	root_window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	# Ensure the canvas stays centered; Godot handles letterboxing when aspect is KEEP.


func _connect_inputs() -> void:
	if is_instance_valid(start_button) and not start_button.pressed.is_connected(_on_user_activation):
		start_button.pressed.connect(_on_user_activation)
	if is_instance_valid(overlay) and not overlay.gui_input.is_connected(_on_overlay_gui_input):
		overlay.gui_input.connect(_on_overlay_gui_input)


func _pause_for_user_activation() -> void:
	get_tree().paused = true
	_show_overlay()


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
	JavaScriptBridge.eval("console.log('Engine started')")
	_start_spawner()
	get_tree().paused = false
	_hide_overlay()
	Events.web_ready.emit()
	start_game_requested.emit(base_url)


func _start_spawner() -> void:
	if spawner_path.is_empty():
		return
	var spawner: Node = get_node_or_null(spawner_path)
	if spawner == null:
		return
	if spawner.has_method("set_process"):
		spawner.set_process(true)
	if spawner.has_method("set_physics_process"):
		spawner.set_physics_process(true)
	if spawner.has_method("start"):
		spawner.call_deferred("start")
	# If Spawner auto-starts, this safely does nothing.


func _unmute_audio() -> void:
	AudioServer.set_bus_mute(0, false)
	AudioServer.set_bus_volume_db(0, 0.0)


func _show_overlay() -> void:
	if is_instance_valid(overlay):
		overlay.visible = true
		overlay.mouse_filter = Control.MOUSE_FILTER_STOP


func _hide_overlay() -> void:
	if is_instance_valid(overlay):
		overlay.visible = false
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
