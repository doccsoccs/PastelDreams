extends Sprite2D

@export var speed : float = 0.1

# Called when the node enters the scene tree for the first time.
func _ready():
	$AnimationPlayer.play("menurelax")

func _process(_delta):
	position.x += speed
	position.y += speed/2
