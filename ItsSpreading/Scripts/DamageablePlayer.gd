extends Node

class_name DamageablePlayer

@export var health : int = 1
	
func hit(damage : int):
	health -= damage
	
	if health <= 0:
		get_parent().game_over()
