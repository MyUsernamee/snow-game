extends Node3D

@onready var camera = $CharacterBody3D/Head/Camera3D
@onready var head = $CharacterBody3D/Head
@onready var character = $CharacterBody3D

# Collisions
@onready var standing_collision = $CharacterBody3D/StandingCollision
@onready var crouching_collision = $CharacterBody3D/CrouchingCollision

@export var sensitivity = 0.00075

# Ground stuff
@export var ground_acceleration = 10
@export var walk_speed = 3
@export var sprint_speed = 8
@export var jump_speed = 3
@export var friction = 10

@onready var step_sounds: Array[AudioStream] = [
	load("res://Sounds/footstep_1.wav"),
	load("res://Sounds/footstep_2.wav"),
	load("res://Sounds/footstep_3.wav"),
]

# Air stuff
@export var air_speed = 1
@export var air_acceleration = 10000

@export var gravity = 9.81

var bob_t = 0
var bob = Vector3.ZERO
var distance = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func apply_friction(velocity: Vector3, delta) -> Vector3:
	velocity /= 1 + (friction * delta)
	return velocity
	
func update_velocity_ground(wish_dir: Vector3, velocity: Vector3, speed, delta) -> Vector3:
	velocity = apply_friction(velocity, delta)
	
	var current_speed = velocity.dot(wish_dir)
	var add_speed = clamp(speed - current_speed, 0, ground_acceleration * speed * delta)
	
	return velocity + (wish_dir * add_speed)
	
func update_velocity_air(wish_dir: Vector3, velocity: Vector3, speed, delta) -> Vector3:
	var current_speed = velocity.dot(wish_dir)
	var add_speed = clamp(air_speed - current_speed, 0, air_acceleration * air_speed * delta)
	
	return velocity + (wish_dir * add_speed)

# Crouching crazy!
func do_crouching_ground(character: CharacterBody3D, crouch: bool) -> void:
	# Calculate difference in height between both collision shapes
	var difference = standing_collision.shape.height - crouching_collision.shape.height
	
	if crouch && !standing_collision.disabled:
		character.position.y -= difference
	if !crouch && standing_collision.disabled:
		character.position.y += difference
		
	standing_collision.disabled = crouch
	crouching_collision.disabled = !crouch
	
func do_crouching_air(character: CharacterBody3D, crouch: bool) -> void:
	standing_collision.disabled = crouch
	crouching_collision.disabled = !crouch
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var wish_dir = head.basis * Vector3(input_dir.x, 0, input_dir.y)
	
	var jump = Input.is_action_pressed("jump")
	var sprint = Input.is_action_pressed("sprint")
	var crouch = false
	
	var speed = sprint_speed if sprint else walk_speed

	# Gravity
	character.velocity -= Vector3.UP * gravity * delta

	# Crouching and Gravity
	if character.is_on_floor():
		do_crouching_ground(character, crouch)
	else:
		do_crouching_air(character, crouch)
	
	# Jump
	if character.is_on_floor() && jump:
		character.velocity.y = jump_speed
	
	if character.is_on_floor() && !jump:
		# Acceleration
		character.velocity = update_velocity_ground(wish_dir, character.velocity, speed, delta)
		
		# Bob
		if wish_dir:
			# Bob
			bob_t += delta * character.velocity.length()
			distance += delta * character.velocity.length()
			bob.x = sin(bob_t * 4)
			bob.y = sin(bob_t * 4 * 0.5)
			bob.z = sin(bob_t * 4 * 1)
		else:
			bob_t = 0
			distance = 0
			bob *= 0.9
			
		if distance > PI * 3.0 / 8.0:
			distance = 0
			var step = step_sounds[randi() % step_sounds.size()]
			Audio.play_sound(step)

	else: if !character.is_on_floor():
		character.velocity = update_velocity_air(wish_dir, character.velocity, speed, delta)
		
	var bob_scale = Vector3(0.005, 0.05, 0.0075) if sprint else Vector3(0.01, 0.05, 0.005)
	camera.transform.origin = Vector3(bob.y, bob.x, 0) * bob_scale
	head.rotation.z = bob.y * -bob_scale.z
	camera.rotation.y = bob.y * -bob_scale.z
	head.rotation.x = bob.z * -bob_scale.z
	
	character.move_and_slide()

func _input(event):
	if event is InputEventMouseMotion:
		var delta = event.relative
		head.rotation.y -= delta.x * sensitivity
		
		camera.rotation.x -= delta.y * sensitivity
		camera.rotation.x = clamp(camera.rotation.x, -PI * 0.5, PI * 0.5)
