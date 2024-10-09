extends Node

var level_complete : bool = false
var alive_count : int = 0

func _process(_delta):
	for child in get_children():
		if child is Enemy:
			if !child.is_dead:
				alive_count += 1
	
	if alive_count == 0:
		level_complete = true
		get_node("Bed").animation_player.play("active")
	else:
		alive_count = 0
