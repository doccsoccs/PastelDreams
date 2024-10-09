extends Area2D

@export var damage : int = 1

@onready var player : CharacterBody2D = get_parent().get_parent()

func _on_body_entered(body):
	for child in body.get_children():
		if child is Damageable:
			child.hit(damage)
			get_parent().get_parent().just_hit_enemy = true
			
			# Bounce for spin attack
			if player.spinning:
				player.velocity.y = -200
