extends Node3D
class_name ThirdPersonCamera

@export_range(3.0, 12.0, 0.1) var follow_distance := 7.2
@export_range(1.0, 5.0, 0.1) var follow_height := 2.3
@export_range(-75.0, 10.0, 1.0) var min_pitch_degrees := -62.0
@export_range(-75.0, 10.0, 1.0) var max_pitch_degrees := 8.0
@export_range(1.0, 30.0, 0.1) var smoothing := 12.0

var player: CharacterBody3D
var touch_look := Vector2.ZERO
var yaw := 0.0
var pitch := deg_to_rad(-12.0)
var pivot: Node3D
var spring_arm: SpringArm3D
var camera: Camera3D

func _ready() -> void:
	pivot = Node3D.new()
	pivot.name = "CameraPivot"
	add_child(pivot)
	spring_arm = SpringArm3D.new()
	spring_arm.name = "CameraSpringArm"
	spring_arm.spring_length = follow_distance
	spring_arm.margin = 0.25
	spring_arm.collision_mask = 1
	pivot.add_child(spring_arm)
	camera = Camera3D.new()
	camera.name = "FlightCamera"
	camera.current = true
	camera.fov = 70.0
	spring_arm.add_child(camera)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func bind_player(value: CharacterBody3D) -> void:
	player = value
	if player:
		yaw = player.rotation.y
		global_position = player.global_position + Vector3.UP * follow_height

func add_touch_look(delta: Vector2) -> void:
	touch_look += delta

func _unhandled_input(event: InputEvent) -> void:
	if not GameState.is_playing():
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_rotate_camera(event.relative)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event.is_action_pressed("pause_game"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _process(delta: float) -> void:
	if not is_instance_valid(player):
		return
	if GameState.is_playing():
		if touch_look.length_squared() > 0.0:
			_rotate_camera(touch_look)
			touch_look = Vector2.ZERO
		if Input.is_action_just_pressed("target_lock") and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	pitch = clampf(pitch, deg_to_rad(min_pitch_degrees), deg_to_rad(max_pitch_degrees))
	var desired_position := player.global_position + Vector3.UP * follow_height
	global_position = global_position.lerp(desired_position, 1.0 - exp(-smoothing * delta))
	pivot.rotation = Vector3(pitch, yaw, 0.0)
	if player.has_method("get_bank_amount"):
		pivot.rotation.z = float(player.get_bank_amount()) * 0.35
	spring_arm.spring_length = lerpf(spring_arm.spring_length, follow_distance, 1.0 - exp(-5.0 * delta))

func _rotate_camera(screen_delta: Vector2) -> void:
	var sensitivity := float(SaveManager.settings.get("camera_sensitivity", 0.12))
	yaw -= screen_delta.x * sensitivity * 0.01
	pitch = clampf(
		pitch - screen_delta.y * sensitivity * 0.01,
		deg_to_rad(min_pitch_degrees),
		deg_to_rad(max_pitch_degrees)
	)

func get_camera() -> Camera3D:
	return camera
