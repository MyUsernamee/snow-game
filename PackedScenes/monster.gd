extends Node3D

@onready var player = $/root/Root.player

enum State {

	HIDDEN,
	WATCHING,
	APPROACHING,
	RUNNING

}

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
