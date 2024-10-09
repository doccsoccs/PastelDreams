extends CharacterBody2D

class_name Enemy

var voidGrow : Vector2 = Vector2(0.1, 0.1)

@export var is_dead : bool = false

@onready var area : Area2D = $Area2D
@onready var animation_player : AnimationPlayer = $AnimationPlayer

func _ready():
	animation_player.play("idle")

func growing():
	scale += voidGrow
