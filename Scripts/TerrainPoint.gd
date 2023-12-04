class_name TerrainPoint

var height: float
var color: Color
var type: int

func _init(_height, _color, _type):
	self.height = _height
	self.color = _color
	self.type = _type

func get_height():
	return self.height

func get_color():
	return self.color

func get_type():
	return self.type