extends Control

func _ready():
	$MenuButtons/PlayButton.pressed.connect(_on_play_pressed)
	$MenuButtons/InstructionsButton.pressed.connect(_on_instructions_pressed)
	$MenuButtons/ExitButton.pressed.connect(_on_exit_pressed)

func _on_play_pressed():
	get_tree().change_scene_to_file("res://Main.tscn")

func _on_instructions_pressed():
	get_tree().change_scene_to_file("res://Instructions.tscn")

func _on_exit_pressed():
	get_tree().quit()
