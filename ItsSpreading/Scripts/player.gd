extends CharacterBody2D

@export var speed : float = 300.0
@export var jumpVelocity : float = -700.0
var direction : Vector2 = Vector2.ZERO

# Buffers
@export var jumpBufferTime : float = 0.1
@export var coyoteBufferTime : float = 0.1
@export var wallBufferTime : float = 0.1
@export var wallCoyoteBufferTime : float = 0.15
var jumpBufferTimer
var coyoteBufferTimer
var wallBufferTimer
var wallCoyoteBufferTimer

# Wall Jumps/Slides
@export var controlOffTime : float = 0.36
var wallJumpTimer
var wallJumping : bool = false

# Movement
@export var skiddingValue : float = 2.0
var currentSkiddingValue

# Hit Launch
var hitLaunchVector : Vector2 = Vector2(200, -500)
var launchTime : float = 0.2
var launchTimer : float
var launching : bool = false
var headingUp : bool = false

# Attacks
var attacking : bool = false
var mousePos : Vector2
const maxDistance : float = 60
var just_hit_enemy : bool = false

# Spinning
var spinning : bool = false
var spin_attack_window : bool = false
var spinningTime : float = 2.0
var spinningTimer : float

# Resting
var rest_time : float = 3
var rest_timer : float = 0
var is_resting : bool = false
var idling : bool = false

# Holds all spritesheets
var flipped : bool = false
var spriteArray : Array
var activeSprite
enum Sprites {idle, run, stoprun, jump, squish, attack, recovery, die, resting, spin}

# Game Over
var is_dead : bool = false

# No controls on start up until X amount of time
var controls_inactive_time = 0.1
var controls_inactive_timer = 0
var controls_active : bool = false

# Particles
@export var particles : PackedScene
@export var attack_particles : PackedScene

@onready var player : CharacterBody2D = $"."
@onready var animationTree : AnimationTree = $AnimationTree
@onready var geometryCollision : RayCast2D = $geometryCollision
@onready var jump_audio = $jump_audio
@onready var spin_audio = $spin_audio

# Get the gravity from the project settings to be synced with RigidBody nodes.
var defaultGravity : float = ProjectSettings.get_setting("physics/2d/default_gravity")
var fastFallGravity : float = 3200
var gravity : float

# START
func _ready():
	# INIT GRAVITY
	gravity = defaultGravity
	
	# INIT ANIMATION
	animationTree.active = true
	activeSprite = Sprites.idle
	
	# Initialize timers to the time to count
	jumpBufferTimer = jumpBufferTime
	coyoteBufferTimer = coyoteBufferTime
	wallBufferTimer = wallBufferTime
	wallCoyoteBufferTimer = wallCoyoteBufferTime
	launchTimer = launchTime
	
	# Movement
	currentSkiddingValue = skiddingValue
	
	# Add Sprites to List
	spriteArray.push_back($Idle)
	spriteArray.push_back($Run)
	spriteArray.push_back($StopRun)
	spriteArray.push_back($Jump)
	spriteArray.push_back($Squish)
	spriteArray.push_back($Attack)
	spriteArray.push_back($Recovery)
	spriteArray.push_back($Die)
	spriteArray.push_back($Resting)
	spriteArray.push_back($Spin)

# MAIN UPDATE LOOP
func _process(delta):
	
	# Prevent jitter at start up
	if controls_inactive_timer < controls_inactive_time:
		controls_inactive_timer += delta
	else:
		controls_active = true
	
	# Reset on leave bounds
	if position.y > 1040:
		is_dead = true
	
	# Run Animation Logic
	updateVisibility()
	flipSprite()
	updateAnimationParameters()
	
	# Long Idle Animation
	if idling:
		rest_timer += delta
	else:
		rest_timer = 0
	
	if rest_timer > rest_time:
		is_resting = true
	else:
		is_resting = false
	
	# Cling to wall + wall jump
	# Don't cling after and during attacks
	if is_on_wall() and not is_on_floor() and activeSprite != Sprites.attack:
		
		# Only wall slide when falling
		if velocity.y > 0 and !wallJumping and !is_dead:
			wallSlide()
			
		# Wall Jump when input is pressed and not already walljumping
		if Input.is_action_just_pressed("ui_accept") and !wallJumping and !is_dead and controls_active:
			wallJump()
			wallCoyoteBufferTimer = 0
	
	# Wall Jump with Coyote time
	elif Input.is_action_just_pressed("ui_accept") and wallCoyoteBufferTimer >= 0 \
		 and wallCoyoteBufferTimer < wallCoyoteBufferTime and controls_active:
		wallJump()
		
	# Wall Jump Coyote Buffer
	else:
		wallCoyoteBufferTimer -= delta
	
	# When jump is pressed in the air while not on the wall or attacking --> Buffer Input
	if Input.is_action_just_pressed("ui_accept") and not is_on_wall() and not is_on_floor() \
	and activeSprite != Sprites.attack and controls_active:
		wallBufferTimer = wallBufferTime
	
	# Track the time while wall jumping to know when to return control to the player
	if wallJumping:
		wallJumpTimer += delta
	else:
		wallJumpTimer = 0
	
	# Return control to the player
	if wallJumpTimer > controlOffTime:
		wallJumping = false
	
	# Launch Timer
	if launching and launchTimer >= 0:
		launchTimer -= delta
	elif launchTimer < 0:
		launching = false
		launchTimer = launchTime

# MAIN PHYSICS UPDATE LOOP
func _physics_process(delta):
	# ----------------- Falling Logic -------------------
	# Add the gravity.
	if not is_on_floor():
		# Stop in midair if attacking
		if attacking and activeSprite != Sprites.recovery:
			velocity = Vector2.ZERO
			
		# Fall
		else:
			velocity.y += gravity * delta
			
			# Buffer jump time while falling
			jumpBufferTimer -= delta
			coyoteBufferTimer -= delta
			wallBufferTimer -= delta
		
		# FAST FALL
		if Input.is_action_pressed("ui_down") and not is_on_wall() and controls_active:
			gravity = fastFallGravity
		else:
			gravity = defaultGravity
		
	else:
		# Jump if started the Jump Buffer and within timing window
		if jumpBufferTimer >= 0 and jumpBufferTimer < jumpBufferTime:
			velocity.y = jumpVelocity
			jump_audio.play()
			
		# Walljump if started the WallJump buffer within the window
		if wallBufferTimer >= 0 and wallBufferTimer < wallBufferTime \
								and is_on_wall() and not is_on_floor():
			wallJump()
			
		# Reset buffer when touches ground
		coyoteBufferTimer = coyoteBufferTime
	
	# ----------------- Jump Logic -------------------
	# Jump While On Ground.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor() and !wallJumping and !is_dead and controls_active:
		velocity.y = jumpVelocity
		jump_audio.play()
	
	# Buffer Logic
	elif Input.is_action_just_pressed("ui_accept") and not is_on_floor() and !wallJumping and !is_dead and controls_active:
		
		# Start buffer when pressing jump in the air
		jumpBufferTimer = jumpBufferTime
		
		# Coyote Buffer
		if coyoteBufferTimer < coyoteBufferTime and coyoteBufferTimer >= 0:
			coyoteBufferTimer = coyoteBufferTime
			velocity.y = jumpVelocity
			jump_audio.play()

	# Raycast jump forgiveness (arbitrary values)
	if $outsideRight.is_colliding() and !$center.is_colliding() \
		and !$center.is_colliding() and !$outsideLeft.is_colliding():
			player.global_position.x -= 7
	elif $outsideLeft.is_colliding() and !$center.is_colliding() \
		and !$center.is_colliding() and !$outsideRight.is_colliding():
			player.global_position.x += 7
	
	# Apply a horizontal force while wall jumping
	if wallJumping:
		velocity.x -= speed	* direction.x
	
	# ----------------- Movement Logic -------------------
	if attacking and activeSprite != Sprites.recovery:
		direction = Vector2.ZERO 
	elif Input.is_action_pressed("ui_left") and !wallJumping and !is_dead and controls_active:
		direction.x = -1
	elif Input.is_action_pressed("ui_right") and !wallJumping and !is_dead and controls_active:
		direction.x = 1
	else:
		direction.x = 0
	
	if not wallJumping:
		velocity.x = direction.x * speed

	# ----------------- Attack Logic ---------------------
	if Input.is_action_just_pressed("Attack") and !is_dead and controls_active:
		
		# Only get the attack target while not attacking
		if activeSprite != Sprites.attack:
			just_hit_enemy = false
			mousePos = get_global_mouse_position()
			
			# Flip the player sprite if needed
			if mousePos.x < player.position.x:
				flipped = true
				for sprite in spriteArray:
					sprite.flip_h = flipped
			else:
				flipped = false
				for sprite in spriteArray:
					sprite.flip_h = flipped
			
		#Initiate attack
		if !spinning or (spinning and spinningTimer >= spinningTime/6):
			spinningTimer = 0
			spinning = false
			attacking = true
			
	elif Input.is_action_pressed("SpinAttack") and !is_dead and activeSprite == Sprites.attack and controls_active:
		spinning = true
		spinningTimer = 0
			
	# Spin Attack
	if Input.is_action_pressed("SpinAttack") and !is_dead and activeSprite == Sprites.recovery and controls_active:
		spinning = true
		spinningTimer = 0
	
	# Spin Attack Timer
	if spinning and activeSprite == Sprites.spin:
		if spinningTimer == 0:
			spin_audio.play()
		spinningTimer += delta
	if spinningTimer > spinningTime or is_on_floor() or wallJumping:
		spinning = false
		$Spin/SpinAttackHit.monitoring = false
	
	# Keep attack hitbox facing right direction
	if flipped:
		$Attack/AttackHit.position.x = -43
	else:
		$Attack/AttackHit.position.x = 43
	
	# Get Flung & Rotate
	if activeSprite == Sprites.attack and attacking:
		
		# Get the attack target
		var target : Vector2 = mousePos - player.position
		
		# Raycast
		geometryCollision.target_position = target
		geometryCollision.target_position = geometryCollision.target_position.limit_length(maxDistance)
		
		# Clamp Movement
		if geometryCollision.is_colliding():
			var collisionPos : Vector2 = geometryCollision.get_collision_point()
			var distance : float = player.position.distance_to(collisionPos)
			target = target.limit_length(distance)
		else:
			target = target.limit_length(maxDistance)
		
		# Find Headinga
		if Input.is_action_pressed("ui_down") and controls_active:
			headingUp = false
		else:
			headingUp = true
		
		# Rotation: don't rotate on geometry		
		if not is_on_floor() and not is_on_ceiling() and not is_on_wall():
			var rotatePlayer : float = atan(target.y / target.x)
			player.rotation = rotatePlayer
		
		# Don't move into geometry
		if !flipped:
			geometryCollision.target_position = Vector2(36, 0)
		else:
			geometryCollision.target_position = Vector2(-36, 0)
		if not geometryCollision.is_colliding():
			player.global_position += target / 5
	
	# Reset rotation while not attacking
	else:
		geometryCollision.target_position = Vector2.ZERO
		player.rotation = 0
	
	# ---------- Additional Movement Functions -----------
	skidding()
	hitLauncher()
	jumpAndFallFrames()
	move_and_slide()
	
	# Stop moving if dead
	if is_dead:
		velocity = Vector2.ZERO

# ----------------- Movement Functions -------------------
func wallSlide():
	if !spinning:
		velocity.y = 30
		if velocity.y < 0:
			velocity.y = 0
		wallCoyoteBufferTimer = wallCoyoteBufferTime
	
func wallJump():
	if velocity.y >= jumpVelocity/4:
		velocity.y = jumpVelocity
		wallJumping = true
		jump_audio.play()

func startLaunch():
	if just_hit_enemy:
		launching = true

# Launches the player when hitting an enemy
func hitLauncher():
	if launching and headingUp:
		if Input.is_action_pressed("ui_right"):
			velocity = Vector2(hitLaunchVector.x, hitLaunchVector.y/1.2)
		elif Input.is_action_pressed("ui_left"):
			velocity = Vector2(-hitLaunchVector.x, hitLaunchVector.y/1.2)
		elif !flipped:
			velocity = Vector2(-hitLaunchVector.x, hitLaunchVector.y/1.2)
		else:
			velocity = Vector2(-hitLaunchVector.x, hitLaunchVector.y/1.2)
	elif launching and !headingUp:
		if Input.is_action_pressed("ui_right"):
			velocity = Vector2(hitLaunchVector.x, -hitLaunchVector.y/1.2)
		elif Input.is_action_pressed("ui_left"):
			velocity = Vector2(-hitLaunchVector.x, -hitLaunchVector.y/1.2)
		elif !flipped:
			velocity = Vector2(-hitLaunchVector.x, -hitLaunchVector.y/1.2)
		else:
			velocity = Vector2(-hitLaunchVector.x, -hitLaunchVector.y/1.2)

func skidding():
	# Determine direction based on the direction the player is faced
	if activeSprite == Sprites.stoprun and !flipped:
		player.global_position.x += currentSkiddingValue
	elif activeSprite == Sprites.stoprun and flipped:
		player.global_position.x -= currentSkiddingValue
	
	# Reset value while not skidding
	else:
		currentSkiddingValue = skiddingValue
	
	# Always above 0
	if currentSkiddingValue > 0 and currentSkiddingValue - 0.2 > 0:
		currentSkiddingValue -= 0.15

func setAttackBool(isAttacking: bool):
	attacking = isAttacking

func attackParticles():
	var effect_instance = attack_particles.instantiate()
	effect_instance.position = Vector2.ZERO
	add_child(effect_instance)
	effect_instance.emitting = true

func rechargedAttack():
#	pass
	var effect_instance = particles.instantiate()
	effect_instance.position = Vector2.ZERO
	add_child(effect_instance)
	effect_instance.emitting = true

func jumpAndFallFrames():
	if activeSprite == Sprites.jump:
		var jumpSubdivisions : float = jumpVelocity / 5
		if abs(velocity.y) <= abs(jumpVelocity) and abs(velocity.y) > abs(jumpSubdivisions * 4):
			$Jump.frame = 0
		elif abs(velocity.y) <= abs(jumpSubdivisions * 4) and abs(velocity.y) > abs(jumpSubdivisions * 3):
			$Jump.frame = 1
		elif abs(velocity.y) <= abs(jumpSubdivisions * 3) and abs(velocity.y) > abs(jumpSubdivisions * 2):
			$Jump.frame = 2
		elif abs(velocity.y) <= abs(jumpSubdivisions * 2) and abs(velocity.y) > abs(jumpSubdivisions):
			$Jump.frame = 3
		elif abs(velocity.y) <= abs(jumpSubdivisions) and abs(velocity.y) > abs(0):
			$Jump.frame = 4

# ----------------- Animation Functions -------------------
func updateVisibility():
	match activeSprite:
		Sprites.idle: 
			switchToSprite($Idle)
		Sprites.run: 
			switchToSprite($Run)
		Sprites.stoprun: 
			switchToSprite($StopRun)
		Sprites.jump:
			switchToSprite($Jump)
		Sprites.squish:
			switchToSprite($Squish)
		Sprites.attack:
			switchToSprite($Attack)
		Sprites.recovery:
			switchToSprite($Recovery)
		Sprites.die:
			switchToSprite($Die)
		Sprites.resting:
			switchToSprite($Resting)
		Sprites.spin:
			switchToSprite($Spin)

func setEnum(active: int):
	activeSprite = active

# Sets visibility of all sprites in the array to false
# except for the sprite that is passed in
func switchToSprite(s: Sprite2D):
	if s.visible:
		return
	for sprite in spriteArray:
		if sprite != s:
			sprite.visible = false
		else:
			sprite.visible = true

# Track which direction the sprite is facing
func flipSprite():
	if velocity != Vector2.ZERO and !attacking:
		# LEFT
		if velocity.x < 0:
			flipped = true
			for sprite in spriteArray:
				sprite.flip_h = flipped
		# RIGHT
		elif velocity.x > 0:
			flipped = false
			for sprite in spriteArray:
				sprite.flip_h = flipped

# Updates the conditions used to transition between animations
func updateAnimationParameters():
	if is_dead:
		idling = false
		animationTree["parameters/conditions/idle"] = false
		animationTree["parameters/conditions/running"] = false
		animationTree["parameters/conditions/jumping"] = false
		animationTree["parameters/conditions/attacking"] = false
		animationTree["parameters/conditions/death"] = true
		animationTree["parameters/conditions/resting"] = false
		animationTree["parameters/conditions/spinning"] = false
	elif is_resting:
		idling = false
		animationTree["parameters/conditions/idle"] = false
		animationTree["parameters/conditions/running"] = false
		animationTree["parameters/conditions/jumping"] = false
		animationTree["parameters/conditions/attacking"] = false
		animationTree["parameters/conditions/death"] = false
		animationTree["parameters/conditions/resting"] = true
		animationTree["parameters/conditions/spinning"] = false
	elif attacking:
		idling = false
		animationTree["parameters/conditions/idle"] = false
		animationTree["parameters/conditions/running"] = false
		animationTree["parameters/conditions/jumping"] = false
		animationTree["parameters/conditions/attacking"] = true
		animationTree["parameters/conditions/death"] = false
		animationTree["parameters/conditions/resting"] = false
		animationTree["parameters/conditions/spinning"] = false
	elif spinning:
		idling = false
		animationTree["parameters/conditions/idle"] = false
		animationTree["parameters/conditions/running"] = false
		animationTree["parameters/conditions/jumping"] = false
		animationTree["parameters/conditions/attacking"] = false
		animationTree["parameters/conditions/death"] = false
		animationTree["parameters/conditions/resting"] = false
		animationTree["parameters/conditions/spinning"] = true
	# JUMPING / FALLING
	elif not is_on_floor():
		idling = false
		animationTree["parameters/conditions/idle"] = false
		animationTree["parameters/conditions/running"] = false
		animationTree["parameters/conditions/jumping"] = true
		animationTree["parameters/conditions/attacking"] = false
		animationTree["parameters/conditions/death"] = false
		animationTree["parameters/conditions/resting"] = false
		animationTree["parameters/conditions/spinning"] = false
	# RUNNING
	elif is_on_floor() and velocity != Vector2.ZERO:
		idling = false
		animationTree["parameters/conditions/idle"] = false
		animationTree["parameters/conditions/running"] = true
		animationTree["parameters/conditions/jumping"] = false
		animationTree["parameters/conditions/attacking"] = false
		animationTree["parameters/conditions/death"] = false
		animationTree["parameters/conditions/resting"] = false
		animationTree["parameters/conditions/spinning"] = false
	# NOT MOVING
	elif is_on_floor() and velocity == Vector2.ZERO:
		idling = true
		animationTree["parameters/conditions/idle"] = true
		animationTree["parameters/conditions/running"] = false
		animationTree["parameters/conditions/jumping"] = false
		animationTree["parameters/conditions/attacking"] = false
		animationTree["parameters/conditions/death"] = false
		animationTree["parameters/conditions/resting"] = false
		animationTree["parameters/conditions/spinning"] = false
	
func game_over():
	is_dead = true

func reset_scene():
	get_node("/root/DeathTracker").has_died = true
	get_tree().reload_current_scene()
