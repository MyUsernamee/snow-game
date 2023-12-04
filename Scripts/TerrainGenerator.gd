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

			var height1 = get_noise(x, y)
			var height2 = get_noise(x + 1, y)
			var height3 = get_noise(x, y + 1)
			var height4 = get_noise(x + 1, y + 1)

			st.set_color(height.get_color())
			st.add_vertex(Vector3(x, height1.get_height(), y))
			st.set_color(height2.get_color())
			st.add_vertex(Vector3(x + 1, height2.get_height(), y))
			st.set_color(height3.get_color())
			st.add_vertex(Vector3(x, height3.get_height(), y + 1))
			st.set_color(height4.get_color())
			st.add_vertex(Vector3(x + 1, height4.get_height(), y + 1))

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

	var terrain_point = TerrainPoint.new(noise.get_noise_2d(x, y) * noise.get_noise_2d(x / 100, y / 100), Color(0, 1, 0, 1), 0)
	return terrain_point