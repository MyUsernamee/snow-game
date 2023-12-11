extends Camera3D

var time = 0.0;

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	time += delta
	position = Vector3(cos(time), 1.0, sin(time)) * 50.0
	look_at(Vector3(0, 0, 0), Vector3(0, 1, 0))
	pass