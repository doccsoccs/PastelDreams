extends Area2D

@onready var audio_player = $"../AudioStreamPlayer"

func _on_body_entered(_body):
	if get_parent().get_parent().level_complete:
#		get_tree().reload_current_scene()
#		get_parent().get_parent().get_parent().level_changed.emit(get_parent().get_parent().get_parent().level_name)
#		
		get_node("/root/WinUi").beat_level(self)

func switch_levels():
	get_parent().get_parent().get_parent().next_level()
