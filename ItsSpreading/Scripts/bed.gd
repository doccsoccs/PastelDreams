extends CharacterBody2D

class_name Bed

@onready var current_level : Node = $".".get_parent()
@onready var animation_player : AnimationPlayer = $AnimationPlayer

func _ready():
	animation_player.play("idle")
