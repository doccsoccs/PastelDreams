extends CanvasLayer

@export var index : int = 1
var script_index : String
var file
var json_as_text
var json_as_dict

var char_read_time = 0.03
var char_read_time_slow = 0.03
var char_read_time_fast = 0.003
var char_read_timer = 0
var char_array = []
var count = 0
var display_text : String = ""
var reading : bool = false

var dialogue
var current_dialogue_id

# Sprites
@onready var pastel_sprite = $PastelHeadshot
@onready var noir_sprite = $NoirHeadshot

# Audio
@onready var audio_pastel = $PastelBlip
@onready var audio_noir = $NoirBlip
var pastel_talking : bool = false
var blip_time = 0.03
var blip_timer = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	# Skip dialogue on death
	if !get_node("/root/DeathTracker").has_died:
		get_node("/root/DeathTracker").dialogue_active = true
		get_tree().paused = !get_tree().paused
		
		# WHICH SCRIPT
		match index:
			1:
				script_index = "1"
			2:
				script_index = "2"
			3:
				script_index = "3"
			4:
				script_index = "4"
			5:
				script_index = "5"
			6:
				script_index = "6"
			7:
				script_index = "7"
		
		# Get info from script
		file = "res://json/script" + script_index + ".json"
		json_as_text = FileAccess.get_file_as_string(file)
		json_as_dict = JSON.parse_string(json_as_text)
		dialogue = json_as_dict
		
		current_dialogue_id = -1
		next_script()
	
	# Don't show if not playing
	else:
		$".".visible = false

# NEXT LINE on CLICK/SPACE/RETURN
func _input(event):
	if event.is_action_pressed("progress_dialogue"):
		if !reading:
			next_script()
			char_read_time = char_read_time_slow
		else:
			char_read_time = char_read_time_fast

func _process(delta):
	# Only when reading new line...
	if reading:
		
		# Wait for next character
		char_read_timer += delta
		blip_timer += delta
		
		# Show next character
		if count < char_array.size():
			if char_read_timer >= char_read_time:
				char_read_timer = 0
				display_text += char_array[count]
				count += 1
				$TextBubble/Text.text = display_text
		else:
			reading = false
			char_read_timer = 0
			blip_timer = 0
		
		# No fast blips
		if blip_timer >= blip_time:
			# Audio blip
			if pastel_talking:
				audio_pastel.play()
				blip_timer = 0
			else:
				audio_noir.play()
				blip_timer = 0

# DISPLAY NEXT LINE
func next_script():
	if !reading:
		display_text = ""
		$TextBubble/Text.text = display_text
		
		current_dialogue_id += 1
		
		if current_dialogue_id >= dialogue.size():
			$".".visible = false
			get_node("/root/DeathTracker").dialogue_active = false
			get_tree().paused = !get_tree().paused
			return
		
		$TextBubble/Name.text = dialogue[current_dialogue_id]['name']
		
		# Who is talking?
		if dialogue[current_dialogue_id]['name'] == "Pastel":
			pastel_talking = true
		else:
			pastel_talking = false
		
		if pastel_talking:
			pastel_sprite.visible = true
			noir_sprite.visible = false
		else:
			pastel_sprite.visible = false
			noir_sprite.visible = true
		
		char_array = dialogue[current_dialogue_id]['text'].split()
		
		# Set variables 
		reading = true
		count = 0
