extends Control
class_name MainMenu

"""Main menu UI with start/quit actions and a pulsing title."""

@export var start_button: Button
@export var quit_button: Button
@export var title_label: Label

var _title_tween: Tween


func _ready() -> void:
	if is_instance_valid(start_button):
		start_button.pressed.connect(_on_start_pressed)
	if is_instance_valid(quit_button):
		quit_button.pressed.connect(_on_quit_pressed)
	_start_title_pulse()


func _start_title_pulse() -> void:
	if not is_instance_valid(title_label):
		return
	if is_instance_valid(_title_tween):
		_title_tween.kill()
	title_label.pivot_offset = title_label.size * 0.5
	title_label.scale = Vector2.ONE
	_title_tween = create_tween()
	_title_tween.set_trans(Tween.TRANS_SINE)
	_title_tween.set_ease(Tween.EASE_IN_OUT)
	_title_tween.set_loops()
	_title_tween.tween_property(title_label, "scale", Vector2(1.08, 1.08), 0.8)
	_title_tween.tween_property(title_label, "scale", Vector2.ONE, 0.8)


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()
