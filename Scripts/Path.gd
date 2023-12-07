extends Node3D

class_name Path

var start = Vector3(0, 0, 0)
var path = []


func _init(start_):
	self.start = start_
	self.path = []
	self.path.append(start_)

	