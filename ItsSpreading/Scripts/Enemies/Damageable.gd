extends Node

class_name Damageable

@export var health : int = 1 :
	get:
		return health
	set(value): 
		SignalBus.emit_signal("on_health_changed", get_parent(), value - health)
		health = value

func hit(damage : int):
	health -= damage
	
	if health <= 0:
		get_parent().is_dead = true
		get_parent().animation_player.play("death")

func destroy_self():
	get_parent().animation_player.play("void")
	$"../void_audio".play()

