extends CanvasLayer

@onready var MUSIC_BUS_ID = AudioServer.get_bus_index("Music")
@onready var SFX_BUS_ID = AudioServer.get_bus_index("SFX")
@onready var menu = $Menu
@onready var audio_player = $AudioStreamPlayer

func _ready():
	menu.visible = false

func _input(event):
	if event.is_action_pressed("ui_cancel") and !get_node("/root/DeathTracker").dialogue_active:
		menu.visible = !menu.visible
		get_tree().paused = !get_tree().paused

func _on_music_slider_value_changed(value):
	AudioServer.set_bus_volume_db(MUSIC_BUS_ID, linear_to_db(value))
	AudioServer.set_bus_mute(MUSIC_BUS_ID, value < 0.05)

func _on_sfx_slider_value_changed(value):
	AudioServer.set_bus_volume_db(SFX_BUS_ID, linear_to_db(value))
	AudioServer.set_bus_mute(SFX_BUS_ID, value < 0.05)

# RETURN PRESSED
func _on_return_button_pressed():
	menu.visible = !menu.visible
	get_tree().paused = !get_tree().paused

# RETURN HOVER
func _on_return_button_mouse_entered():
	audio_player.play()

# SLIDERS
func _on_music_slider_drag_ended(_value_changed):
	$Menu/MarginContainer/VBoxContainer/GridContainer/MusicSlider.release_focus()
func _on_sfx_slider_drag_ended(_value_changed):
	$Menu/MarginContainer/VBoxContainer/GridContainer/SFXSlider.release_focus()
