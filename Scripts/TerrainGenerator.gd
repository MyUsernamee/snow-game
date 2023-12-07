extends Node3D

class_name TerrainGenerator

@export var width = 1024
@export var height = 100
@export var scale_ = 10.0

@export var tree_model: PackedScene = load("res://PackedScenes/tree.tscn")

@export var material: Material;

var noise = FastNoiseLite.new()
var path = Path.new(Vector3(0, 0, 0))

func _ready():

	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_color(Color(1, 1, 1, 1))

	var index = 0

	var trees = []

	for x in width:

		for y in width:

			var height1 = get_noise_point(x, y)
			var height2 = get_noise_point(x + 1, y)
			var height3 = get_noise_point(x, y + 1)
			var height4 = get_noise_point(x + 1, y + 1)

			st.set_color(height1.get_color())
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

			if randf() > 0.99:
				var tree = tree_model.instantiate()
				tree.position = Vector3(x - width / 2.0, height1.get_height(), y - width / 2.0)
				tree.rotation = Vector3(0, randf() * 360, 0)
				tree.scale = Vector3(randf() * 0.5 + 0.5, randf() * 0.5 + 0.5, randf() * 0.5 + 0.5)
				add_child(tree)

			index += 4

	st.generate_normals()
	st.generate_tangents()

	

	var mesh = st.commit()

	var static_body_3d = StaticBody3D.new()
	static_body_3d.position = Vector3(-width / 2.0, 0, -width / 2.0)
	add_child(static_body_3d)

	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = mesh
	#material = StandardMaterial3D.new() if material == null else material
	mesh_instance.material_override = material
	static_body_3d.add_child(mesh_instance)

	var concave_collision_shape = CollisionShape3D.new()
	concave_collision_shape.shape = ConcavePolygonShape3D.new()
	concave_collision_shape.shape.set_faces(mesh.get_faces())
	static_body_3d.add_child(concave_collision_shape)


func get_noise_point(x, y):

	var mountain = noise.get_noise_2d(x / scale_, y / scale_) * height
	#mountain = max(mountain, 0.5) # 25% of area is mountatins

	# math.max((noise2d(x / 100, y / 100) * 15) ^ 3, 1)
	var valley = noise.get_noise_2d(x / scale_ * 4.0, y / scale_ * 4.0) * height / 10.0
	valley = max(pow(valley, 3), 1)


	var height_ = mountain / valley

	var terrain_point = TerrainPoint.new(height_, Color(1, 1, 1, 1), 0)
	return terrain_point