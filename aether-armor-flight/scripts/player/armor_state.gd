extends Node3D
class_name ArmorState

var flight_pose := "grounded"
var left_thruster: MeshInstance3D
var right_thruster: MeshInstance3D
var back_thruster: MeshInstance3D
var reactor: MeshInstance3D
var red_material: StandardMaterial3D
var gold_material: StandardMaterial3D
var dark_material: StandardMaterial3D
var cyan_material: StandardMaterial3D
var time := 0.0

func _ready() -> void:
	_make_materials()
	_build_suit()

func _make_materials() -> void:
	red_material = _metal(Color("#a91f2d"), 0.28, 0.24)
	gold_material = _metal(Color("#d99b38"), 0.3, 0.21)
	dark_material = _metal(Color("#182332"), 0.48, 0.34)
	cyan_material = _metal(Color("#23dfff"), 0.2, 0.12)
	cyan_material.emission_enabled = true
	cyan_material.emission = Color("#00cfff")
	cyan_material.emission_energy_multiplier = 3.2

func _metal(color: Color, metallic: float, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = roughness
	return material

func _build_suit() -> void:
	# Torso and layered chest shell.
	_sphere("TorsoCore", Vector3(0, 0.12, 0), Vector3(0.42, 0.58, 0.27), dark_material)
	_sphere("ChestShell", Vector3(0, 0.39, -0.015), Vector3(0.5, 0.38, 0.29), red_material)
	_sphere("UpperChestLeft", Vector3(-0.2, 0.39, -0.2), Vector3(0.27, 0.22, 0.12), gold_material)
	_sphere("UpperChestRight", Vector3(0.2, 0.39, -0.2), Vector3(0.27, 0.22, 0.12), gold_material)
	_sphere("AbdomenPlate1", Vector3(0, 0.02, -0.19), Vector3(0.33, 0.15, 0.14), gold_material)
	_sphere("AbdomenPlate2", Vector3(0, -0.18, -0.18), Vector3(0.3, 0.13, 0.13), red_material)
	_sphere("AbdomenPlate3", Vector3(0, -0.34, -0.15), Vector3(0.27, 0.1, 0.12), gold_material)
	_cylinder("ChestReactorRim", Vector3(0, 0.4, -0.3), 0.17, 0.055, 0.04, gold_material, Vector3(PI / 2.0, 0, 0))
	reactor = _sphere("CyanChestReactor", Vector3(0, 0.4, -0.34), Vector3(0.115, 0.115, 0.045), cyan_material)

	# Original faceted helmet, dark visor, and illuminated eye slits.
	_sphere("Neck", Vector3(0, 0.67, 0), Vector3(0.16, 0.13, 0.17), dark_material)
	_sphere("HelmetCrown", Vector3(0, 0.94, 0), Vector3(0.29, 0.35, 0.28), gold_material)
	_sphere("HelmetShell", Vector3(0, 0.91, -0.08), Vector3(0.26, 0.3, 0.25), red_material)
	_sphere("Faceplate", Vector3(0, 0.84, -0.27), Vector3(0.205, 0.18, 0.075), dark_material)
	_sphere("VisorLeft", Vector3(-0.095, 0.9, -0.33), Vector3(0.075, 0.023, 0.018), cyan_material)
	_sphere("VisorRight", Vector3(0.095, 0.9, -0.33), Vector3(0.075, 0.023, 0.018), cyan_material)
	_sphere("HelmetJaw", Vector3(0, 0.7, -0.22), Vector3(0.17, 0.13, 0.12), gold_material)

	# Shoulder pauldrons, articulated arms, and palm repulsors.
	for side in [-1.0, 1.0]:
		var side_name := "L" if side < 0 else "R"
		_sphere(side_name + "ShoulderJoint", Vector3(side * 0.52, 0.35, 0), Vector3(0.22, 0.23, 0.23), dark_material)
		_sphere(side_name + "Pauldron", Vector3(side * 0.55, 0.39, -0.045), Vector3(0.3, 0.21, 0.28), red_material)
		_sphere(side_name + "PauldronTrim", Vector3(side * 0.55, 0.41, -0.22), Vector3(0.19, 0.11, 0.08), gold_material)
		_capsule(side_name + "UpperArm", Vector3(side * 0.66, 0.03, 0), 0.17, 0.52, gold_material, Vector3(0, 0, side * 0.13))
		_sphere(side_name + "Elbow", Vector3(side * 0.74, -0.22, 0), Vector3(0.14, 0.14, 0.15), dark_material)
		_capsule(side_name + "Forearm", Vector3(side * 0.77, -0.43, -0.01), 0.16, 0.48, red_material, Vector3(0, 0, side * 0.08))
		_sphere(side_name + "ForearmGuard", Vector3(side * 0.79, -0.42, -0.16), Vector3(0.16, 0.27, 0.11), gold_material)
		_sphere(side_name + "Palm", Vector3(side * 0.79, -0.72, -0.09), Vector3(0.18, 0.15, 0.1), dark_material)
		_cylinder(side_name + "PalmEmitterRim", Vector3(side * 0.79, -0.72, -0.19), 0.095, 0.08, 0.035, gold_material, Vector3(PI / 2.0, 0, 0))
		_sphere(side_name + "PalmEmitter", Vector3(side * 0.79, -0.72, -0.225), Vector3(0.062, 0.062, 0.025), cyan_material)
		_sphere(side_name + "Hip", Vector3(side * 0.23, -0.45, 0), Vector3(0.21, 0.2, 0.22), dark_material)
		_capsule(side_name + "Thigh", Vector3(side * 0.24, -0.76, 0.01), 0.205, 0.62, red_material)
		_sphere(side_name + "Knee", Vector3(side * 0.24, -1.04, -0.05), Vector3(0.19, 0.16, 0.19), gold_material)
		_capsule(side_name + "Shin", Vector3(side * 0.24, -1.3, 0.015), 0.17, 0.58, dark_material)
		_sphere(side_name + "ShinPlate", Vector3(side * 0.24, -1.31, -0.12), Vector3(0.16, 0.26, 0.09), gold_material)
		_sphere(side_name + "Boot", Vector3(side * 0.24, -1.56, -0.09), Vector3(0.23, 0.16, 0.34), red_material)
		_cylinder(side_name + "BootNozzle", Vector3(side * 0.24, -1.65, 0.12), 0.105, 0.03, 0.31, cyan_material, Vector3(0, 0, 0))

	# Back plate and twin flight packs.
	_sphere("BackpackShell", Vector3(0, 0.19, 0.28), Vector3(0.39, 0.46, 0.21), dark_material)
	for side in [-1.0, 1.0]:
		_sphere("ThrusterPod", Vector3(side * 0.29, 0.26, 0.39), Vector3(0.16, 0.36, 0.18), red_material)
		_cylinder("BackThrusterNozzle", Vector3(side * 0.29, -0.02, 0.4), 0.12, 0.035, 0.25, cyan_material)
	_sphere("SpineRib1", Vector3(0, 0.25, 0.47), Vector3(0.12, 0.2, 0.07), gold_material)
	_sphere("SpineRib2", Vector3(0, 0.02, 0.44), Vector3(0.1, 0.16, 0.06), gold_material)

	left_thruster = _sphere("LeftBootFlare", Vector3(-0.24, -1.8, 0.12), Vector3(0.11, 0.3, 0.11), cyan_material)
	right_thruster = _sphere("RightBootFlare", Vector3(0.24, -1.8, 0.12), Vector3(0.11, 0.3, 0.11), cyan_material)
	back_thruster = _sphere("BackFlare", Vector3(0, -0.15, 0.55), Vector3(0.2, 0.4, 0.16), cyan_material)
	set_flight_pose("grounded", Vector2.ZERO, false, 100.0)

func _sphere(part_name: String, local_position: Vector3, part_scale: Vector3, material: Material) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = part_name
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh_instance.mesh = mesh
	mesh_instance.position = local_position
	mesh_instance.scale = part_scale * 2.0
	mesh_instance.material_override = material
	add_child(mesh_instance)
	return mesh_instance

func _capsule(part_name: String, local_position: Vector3, radius: float, height: float, material: Material, part_rotation: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = part_name
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh_instance.mesh = mesh
	mesh_instance.position = local_position
	mesh_instance.rotation = part_rotation
	mesh_instance.material_override = material
	add_child(mesh_instance)
	return mesh_instance

func _cylinder(part_name: String, local_position: Vector3, top_radius: float, bottom_radius: float, height: float, material: Material, part_rotation: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = part_name
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_radius
	mesh.bottom_radius = bottom_radius
	mesh.height = height
	mesh.radial_segments = 16
	mesh_instance.mesh = mesh
	mesh_instance.position = local_position
	mesh_instance.rotation = part_rotation
	mesh_instance.material_override = material
	add_child(mesh_instance)
	return mesh_instance

func set_flight_pose(state_name: String, input_vector: Vector2, boosting: bool, energy: float) -> void:
	flight_pose = state_name
	var active := boosting or state_name in ["takeoff", "ascending", "hover", "flight"]
	var power := 0.45 + energy / 200.0
	for thruster in [left_thruster, right_thruster, back_thruster]:
		if is_instance_valid(thruster):
			thruster.visible = active
			thruster.scale.y = (0.35 if boosting else 0.22) * power
	time += 0.016
	if is_instance_valid(reactor):
		reactor.scale = Vector3.ONE * (0.22 + 0.012 * sin(time * 8.0))
