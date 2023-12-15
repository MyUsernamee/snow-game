extends Node3D

@onready var player = $/root/Root/SubViewportContainer/SubViewport/Player/CharacterBody3D
@onready var player_camera = $/root/Root/SubViewportContainer/SubViewport/Player/CharacterBody3D/Head/Camera3D
@onready var animation: AnimationPlayer = $CharacterBody3D/MonsterModel/AnimationPlayer
@onready var body = $CharacterBody3D
@onready var model = $CharacterBody3D/MonsterModel
@onready var skeleton: Skeleton3D = $CharacterBody3D/MonsterModel/Armature/Skeleton3D
@onready var root_bone = skeleton.find_bone("Root")
@onready var left_leg_ik = $CharacterBody3D/MonsterModel/Armature/Skeleton3D/LeftLeg
@onready var right_leg_ik = $CharacterBody3D/MonsterModel/Armature/Skeleton3D/RightLeg
@onready var left_leg_ik_target = $CharacterBody3D/MonsterModel/Armature/LeftLegMarker
@onready var right_leg_ik_target = $CharacterBody3D/MonsterModel/Armature/RightLegMarker
@onready var left_leg_ik_rest = $CharacterBody3D/MonsterModel/Armature/LeftLegRest
@onready var right_leg_ik_rest = $CharacterBody3D/MonsterModel/Armature/RightLegRest
@onready var head = skeleton.find_bone("Bone.01")
@onready var upper_spine = skeleton.find_bone("UpperSpine")
@onready var head_root = $CharacterBody3D/MonsterModel/Armature/HeadRoot
@onready var head_target = $CharacterBody3D/MonsterModel/Armature/LookTarget
@onready var visible_notifier = $CharacterBody3D/VisibleOnScreenNotifier3D
@export var anger_sound: AudioStream = load("res://Sounds/SCREAM.mp3")

var scenes: Array[PackedScene];

var animation_speed = 0.83333 * 4

enum State {

	HIDDEN,
	WATCHING,
	APPROACHING,
	RUNNING,
	ANGER

}

var current_state = State.HIDDEN

var look_target = Vector3.ZERO
var move_target = Vector3.ZERO

var animation_t = 0.0
var timer = 0.0

func _ready():

	left_leg_ik.start()
	right_leg_ik.start()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):

	update(delta)
	perform_movement(delta)
	animate(delta)
	body.move_and_slide()


func animate(delta):

	animation_t += delta * body.velocity.length()

	var direction = body.velocity.normalized()
	var direction_flat = Vector3(direction.x, 0, direction.z).normalized()

	if direction_flat.length() > 0.0:
		body.global_transform = body.global_transform.looking_at(body.global_transform.origin - direction_flat, Vector3.UP)

	var left_leg_postion = left_leg_ik_rest.global_position + sin(animation_t) * Vector3.UP - cos(animation_t) * direction_flat
	var right_leg_postion = right_leg_ik_rest.global_position + sin(animation_t + PI) * Vector3.UP - cos(animation_t + PI) * direction_flat

	left_leg_ik_target.global_transform.origin = left_leg_postion if fmod(animation_t, PI * 2) < PI else left_leg_ik_target.global_position
	right_leg_ik_target.global_transform.origin = right_leg_postion if fmod(animation_t, PI * 2) > PI else right_leg_ik_target.global_position

	look_at_with_eyes(look_target)

func look_at_with_eyes(target):

	var direction = target - head_root.global_transform.origin
	var direction_flat = direction.normalized()

	head_target.global_transform.origin = direction_flat * 2.0 + head_root.global_transform.origin

func update(delta):

	match current_state:

		State.HIDDEN:
			visible = false

			if randf() < 0.01:
				spawn_monster()
			
		State.WATCHING:
			
			move_target = player.global_transform.origin + (body.global_position - player.global_transform.origin).normalized() * 30.0

			# If we are on screeen
			if not visible_notifier.is_on_screen():
				timer += delta
			else:
				timer -= delta

			if timer < -10.0:
				current_state = State.ANGER
				Audio.play_sound(anger_sound)

			if timer > 3.0:
				current_state = State.APPROACHING
				animation_t = 0.0
				timer = 0.0
				look_target = player.global_transform.origin

		State.APPROACHING:
			
			move_target = player.global_transform.origin

			if visible_notifier.is_on_screen():
				current_state = State.RUNNING
				animation_t = 0.0
				look_target = player.global_transform.origin
			

		State.RUNNING:
			move_target = player.global_transform.origin + (body.global_position - player.global_transform.origin).normalized() * 60.0

			# Once we are far enough away
			if (body.global_position - player.global_transform.origin).length() > 50.0:
				# Hide again
				current_state = State.HIDDEN
				animation_t = 0.0
				visible = false

		State.ANGER:

			move_target = player.global_transform.origin

			if body.global_position.distance_to(player.global_transform.origin) < 3.0:
				get_tree().quit()
			
	look_target = player_camera.global_transform.origin

func perform_movement(delta):

	if body.is_on_floor() && move_target.distance_to(body.global_transform.origin) > 3.0:
		body.velocity = (move_target - body.global_transform.origin).normalized()
		# We flatten the velocity so that the monster doesn't fly
		body.velocity.y = 0.0
		body.velocity = body.velocity.normalized() * 10.0
		pass
	else:
		body.velocity *= 0.9
	
	body.velocity -= Vector3(0, 9.8, 0) * delta

func raycast(origin, end):

	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	query.exclude = [self]

	var result = space_state.intersect_ray(query)
	return result

func spawn_monster():
	
	print("Spawning monster")

	visible = true

	look_target = player.global_transform.origin
	animation_t = 0.0

	# We spawn the monster just outside of the fog behind the player
	var spawn_angle = randf_range(0, PI)
	var spawn_direction = Vector3(cos(spawn_angle), 0, sin(spawn_angle))
	var new_position = player.global_transform.origin + spawn_direction * 50.0

	var new_hit = raycast(new_position + Vector3.UP * 100.0, new_position - Vector3.UP * 100.0)

	if new_hit.collider != null:
		new_position = new_hit.position
		body.global_position = new_position + Vector3.UP * 4.0
		print("Monster spawned on top of something")
		print(new_hit.collider.name)
		print(new_hit.position)
	else:
		new_position = player.global_transform.origin + spawn_direction * 50.0
		body.global_position = new_position + Vector3.UP * 4.0

	print(visible_notifier.is_on_screen())

	if visible_notifier.is_on_screen():
		spawn_monster()
	else:
		current_state = State.WATCHING
		visible = true

	