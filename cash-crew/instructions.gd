extends Control

@export var main_scene_path: String = "res://main_menu.tscn"

func _on_back_pressed() -> void:
	get_tree().call_deferred("change_scene_to_file", main_scene_path)
