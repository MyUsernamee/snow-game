extends Node3D

class_name RoadGenerator

var curve := Curve3D.new()

func _ready():
	pass

func generate_road() -> void:

	generate_curve()
	generate_mesh()
	populate_lights()

func generate_curve():
	# For testing we add just 4 points a long the z axis
	for i in range(4):
		curve.add_point(Vector3(0, 0, i * 10))

func generate_mesh():
	
	curve.set_bake_interval(4.0)
	curve.set_up_vector(Vector3(0, 1, 0))

	var st := SurfaceTool.new()

	st.begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)