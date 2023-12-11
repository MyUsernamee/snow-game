extends Node3D

class_name RoadGenerator

@onready var raycast := $RayCast3D

var curve := Curve3D.new()

func _ready():
	generate_road()
	pass

func generate_road() -> void:

	generate_curve(Vector3(0.0, 0.0, 0.0), Vector3(100.0, 100.0, 0.0))
	generate_mesh()
	#populate_lights()

func generate_curve(start, end):

	var points = []

	for i in range(0, (start - end).length(), 1.0):
		var point = start + (end - start).normalized() * i
		points.append(point)

	curve.clear_points()

	var vector = []

	for point in points:
		vector.append(point.x)
		vector.append(point.y)
		vector.append(point.z)

	var result = sgd(vector, road_error, 1000)

	for index in range(0, result.size(), 3):
		var point = Vector3(result[index], result[index + 1], result[index + 2])
		curve.add_point(point)

	
func road_error(vector):

	var error = 0.0

	for index in range(0, vector.size(), 3):
		var point = Vector3(vector[index], vector[index + 1], vector[index + 2])
		point += Vector3.UP * 1000.0

		# We raycast downards
		var origin = point
		var end = point + Vector3.DOWN * 1000000.0
		var query = PhysicsRayQueryParameters3D.create(origin, end)
		var result = get_world_3d().direct_space_state.intersect_ray(query)
		if result.size() > 0:
			print(result)
			error += result[0].position.y
		
	return error
		

func sgd(vector, function, iterations):
	
	if iterations == 0:
		return vector

	var epsilon = 0.0001
	var delta = function.call(vector)

	for i in range(0, vector.size()):
		var temp = vector[i]
		vector[i] += epsilon
		var delta2 = function.call(vector)
		vector[i] = temp

		var derivative = (delta2 - delta) / epsilon
		vector[i] -= derivative * 0.01

	return sgd(vector, function, iterations - 1)

func generate_mesh():
	
	curve.set_bake_interval(1.0)

	print(curve.get_baked_length())

	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)

	for length in range(0.0, curve.get_baked_length(), 1.0):
		print(length)
		var point = curve.sample_baked_with_rotation(length)
		var right = point.basis.x.normalized()
		right.y = 0.0
		right = right.normalized()

		st.add_vertex(point.origin + right * 10.0)
		st.add_vertex(point.origin - right * 10.0)

	st.index()
	st.generate_normals()
	st.generate_tangents()

	var mesh = st.commit()

	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = mesh
	add_child(mesh_instance)

