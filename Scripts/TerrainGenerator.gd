extends Node3D

class_name TerrainGenerator

@export var width = 1024
@export var height = 40

var noise = FastNoiseLite.new()

func _ready():

	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_color(Color(1, 1, 1, 1))

	var index = 0

	for x in width:
		for y in width:

			var height1 = noise.get_noise_2d(x, y) * height
			var height2 = noise.get_noise_2d(x + 1, y) * height
			var height3 = noise.get_noise_2d(x, y + 1) * height
			var height4 = noise.get_noise_2d(x + 1, y + 1) * height

			st.set_color(Color(height1 / height, 0.0, 0.0, 1.0))
			st.add_vertex(Vector3(x, height1, y))
			st.set_color(Color(height2 / height, 0.0, 0.0, 1.0))
			st.add_vertex(Vector3(x + 1, height2, y))
			st.set_color(Color(height3 / height, 0.0, 0.0, 1.0))
			st.add_vertex(Vector3(x, height3, y + 1))
			st.set_color(Color(height4 / height, 0.0, 0.0, 1.0))
			st.add_vertex(Vector3(x + 1, height4, y + 1))

			st.add_index(index)
			st.add_index(index + 1)
			st.add_index(index + 2)

			st.add_index(index + 1)
			st.add_index(index + 3)
			st.add_index(index + 2)

			index += 4

	st.generate_normals()
	st.generate_tangents()

	var mesh = st.commit()

	var static_body_3d = StaticBody3D.new()
	add_child(static_body_3d)

	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = mesh
	var material = StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	mesh_instance.material_override = material
	static_body_3d.add_child(mesh_instance)

	var concave_collision_shape = CollisionShape3D.new()
	concave_collision_shape.shape = ConcavePolygonShape3D.new()
	concave_collision_shape.shape.set_faces(mesh.get_faces())
	static_body_3d.add_child(concave_collision_shape)

func get_noise(x, y):
	return noise.get_noise_2d(x, y) * noise.get_noise_2d(x / 100, y / 100)