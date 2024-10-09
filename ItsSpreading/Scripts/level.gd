extends Node2D

@export var next_level_name : String = "level"

@onready var audio_player = $AudioStreamPlayer

func next_level():
	get_node("/root/DeathTracker").has_died = false
	get_tree().change_scene_to_file("res://Scenes/" + next_level_name + ".tscn")

# PLAY BUTTON
func _on_play_button_pressed():
	next_level()
func _on_play_button_mouse_entered():
	audio_player.play()

# OPTIONS BUTTON
func _on_options_button_pressed():
	get_node("/root/Ui/Menu").visible = !get_node("/root/Ui/Menu").visible
	get_tree().paused = !get_tree().paused
func _on_options_button_mouse_entered():
	audio_player.play()

# QUIT BUTTON
func _on_quit_button_pressed():
	get_tree().quit()
func _on_quit_button_mouse_entered():
	audio_player.play()
