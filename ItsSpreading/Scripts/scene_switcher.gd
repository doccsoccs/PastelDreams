extends Node

# default level
@onready var current_level = $"Main Menu"

func _ready() -> void:
	current_level.connect("level_changed", self.handle_level_changed)

func handle_level_changed(current_level_name: String):
	var next_level
	var next_level_name: String
	
	match current_level_name:
		"mainmenu":
			next_level_name = "level_1"
		"level1":
			next_level_name = "level_2"
		"level2":
			next_level_name = "main_menu"
		_:
			return
	
	next_level = load("res://Scenes/" + next_level_name + ".tscn").instantiate()
	add_child(next_level)
	next_level.connect("level_changed", self.handle_level_changed)
	current_level.queue_free()
	current_level = next_level
