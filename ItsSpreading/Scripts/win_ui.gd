extends CanvasLayer

var level_switcher

@onready var audio_player = $AudioStreamPlayer
@onready var animations = $AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready():
	visible = false

func beat_level(bed: Area2D):
	get_tree().paused = !get_tree().paused
	visible = !visible
	audio_player.play()
	animations.play("win")
	
	level_switcher = bed

func next_level():
	visible = !visible
	get_tree().paused = !get_tree().paused
	level_switcher.switch_levels()
