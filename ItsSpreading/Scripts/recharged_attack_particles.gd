extends CPUParticles2D

var timer = 0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	timer += delta
	if timer > lifetime:
		emitting = false
		queue_free()
