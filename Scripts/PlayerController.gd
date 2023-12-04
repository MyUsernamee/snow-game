extends Node3D

class_name Player

@onready var character_body = $CharacterBody3D
@onready var camera = $CharacterBody3D/Camera3D

@export var mouse_sensitivity: float = 0.1
@export var move_speed: float = 4
@export var sprint_speed: float = 10
@export var jump_power: float = 10
@export var gravity: float = 9.8 * 4

var sprint_meter: float = 0 # TODO: Implement sprint meter
var cold_meter: float = 0 # TODO: Implement cold meter

var view_direction: Vector3 = Vector3(0, 0, 1)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	view_direction = -camera.global_transform.basis.z

	var movement = Vector3.ZERO
	movement.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	movement.z = Input.get_action_strength("move_forward") - Input.get_action_strength("move_back")

	var local_move_speed = move_speed

	if Input.is_action_pressed("sprint"):
		local_move_speed = sprint_speed

	movement = movement.normalized() * local_move_speed

	if Input.is_action_just_pressed("jump") and character_body.is_on_floor():
		movement.y = jump_power

	var movement_velocity = view_direction * movement.z + view_direction.cross(Vector3.UP) * movement.x 
	movement_velocity.y = movement.y

	character_body.velocity -= Vector3.UP * gravity * delta
	character_body.velocity = character_body.velocity.dot(Vector3.UP) * Vector3.UP # Remove the horizontal component of the velocity
	character_body.velocity += movement_velocity
	character_body.move_and_slide()

func _input(event):

	if event is InputEventMouseMotion:
		camera.rotate_y(deg_to_rad(-event.relative.x * mouse_sensitivity))
		camera.rotate_object_local(Vector3(1, 0, 0), deg_to_rad(-event.relative.y * mouse_sensitivity))
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90), deg_to_rad(90))
