extends CharacterBody3D
class_name FlightController

signal flight_state_changed(state_name: String)
signal weapon_fired
signal energy_updated(current: float, maximum: float)

@export_group("Flight")
@export_range(5.0, 60.0, 0.5) var max_speed := 27.0
@export_range(5.0, 60.0, 0.5) var boost_speed := 44.0
@export_range(5.0, 50.0, 0.5) var acceleration := 22.0
@export_range(0.0, 20.0, 0.1) var air_drag := 3.5
@export_range(5.0, 35.0, 0.5) var vertical_acceleration := 16.0
@export_range(1.0, 40.0, 0.5) var hover_stiffness := 22.0
@export_range(1.0, 20.0, 0.5) var hover_damping := 8.0
@export_range(0.5, 12.0, 0.1) var turn_smoothing := 7.0
@export_range(0.0, 0.8, 0.01) var bank_amount := 0.32
@export_range(0.1, 5.0, 0.1) var boost_drain_per_second := 22.0
@export_range(0.1, 5.0, 0.1) var energy_regen_per_second := 13.0
@export_range(1.0, 20.0, 0.1) var safe_recovery_seconds := 2.0

var camera_rig: ThirdPersonCamera
var armor: ArmorState
var repulsor: RepulsorController
var target_manager: TargetManager
var mobile_move := Vector2.ZERO
var held_actions: Dictionary = {}
var hover_enabled := false
var hover_altitude := 3.2
var suit_energy := 100.0
var flight_state := "grounded"
var safe_position := Vector3.ZERO
var safe_position_timer := 0.0
var recovery_timer := 0.0
var bank := 0.0
var fire_cooldown := 0.0
var landing_requested := false

func _ready() -> void:
	name = "AetherArmor"
	add_to_group("player")
	floor_snap_length = 0.35
	floor_max_angle = deg_to_rad(55.0)
	safe_margin = 0.035
	_build_collision()
	armor = ArmorState.new()
	armor.name = "AetherSuit"
	add_child(armor)
	armor.position = Vector3(0.0, 1.15, 0.0)
	camera_rig = ThirdPersonCamera.new()
	camera_rig.name = "ThirdPersonCamera"
	add_child(camera_rig)
	camera_rig.bind_player(self)
	repulsor = RepulsorController.new()
	repulsor.name = "RepulsorController"
	add_child(repulsor)
	repulsor.bind(self, camera_rig)
	target_manager = TargetManager.new()
	target_manager.name = "TargetManager"
	add_child(target_manager)
	target_manager.bind(self, camera_rig)
	energy_updated.emit(suit_energy, 100.0)
	safe_position = global_position

func _build_collision() -> void:
	var capsule := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.42
	shape.height = 1.65
	capsule.shape = shape
	capsule.position.y = 0.83
	add_child(capsule)

func _physics_process(delta: float) -> void:
	if not GameState.is_playing():
		_clear_actions()
		return
	_update_input_toggles()
	_update_energy(delta)
	_update_flight(delta)
	_update_aim_and_fire(delta)
	_update_recovery(delta)
	_update_safe_position(delta)

func _update_input_toggles() -> void:
	if Input.is_action_just_pressed("hover") or bool(held_actions.get("hover", false)):
		if not bool(held_actions.get("_hover_consumed", false)):
			toggle_hover()
			held_actions["_hover_consumed"] = true
	if not bool(held_actions.get("hover", false)):
		held_actions["_hover_consumed"] = false
	if Input.is_action_just_pressed("target_lock") or bool(held_actions.get("_lock_tap", false)):
		if not bool(held_actions.get("_lock_consumed", false)):
			target_manager.toggle_lock()
			held_actions["_lock_consumed"] = true
	if not bool(held_actions.get("_lock_tap", false)):
		held_actions["_lock_consumed"] = false
	if Input.is_action_just_pressed("recover") or bool(held_actions.get("_recover_tap", false)):
		recover_to_safe_position()
		held_actions["_recover_tap"] = false

func _update_energy(delta: float) -> void:
	var boosting := Input.is_action_pressed("boost") or bool(held_actions.get("boost", false))
	if boosting and suit_energy > 0.0:
		suit_energy = maxf(0.0, suit_energy - boost_drain_per_second * delta)
	else:
		suit_energy = minf(100.0, suit_energy + energy_regen_per_second * delta)
	energy_updated.emit(suit_energy, 100.0)
	GameState.set_energy(suit_energy)

func _update_flight(delta: float) -> void:
	var move_input := Input.get_vector("move_left", "move_right", "move_back", "move_forward")
	move_input += mobile_move
	move_input = move_input.limit_length(1.0)
	var camera := camera_rig.get_camera()
	var camera_right := camera.global_basis.x
	var camera_forward := -camera.global_basis.z
	camera_right.y = 0.0
	camera_forward.y = 0.0
	camera_right = camera_right.normalized()
	camera_forward = camera_forward.normalized()
	var desired_direction := (camera_right * move_input.x + camera_forward * move_input.y).normalized()
	var boosting := (Input.is_action_pressed("boost") or bool(held_actions.get("boost", false))) and suit_energy > 0.0
	var target_speed := boost_speed if boosting else max_speed
	var horizontal_target := desired_direction * target_speed
	if desired_direction.length_squared() > 0.001:
		velocity.x = move_toward(velocity.x, horizontal_target.x, acceleration * delta)
		velocity.z = move_toward(velocity.z, horizontal_target.z, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, air_drag * delta)
		velocity.z = move_toward(velocity.z, 0.0, air_drag * delta)

	var ascend := float(Input.is_action_pressed("ascend") or bool(held_actions.get("ascend", false)))
	var descend := float(Input.is_action_pressed("descend") or bool(held_actions.get("descend", false)))
	var vertical_input := ascend - descend
	landing_requested = Input.is_action_pressed("brake_land") or bool(held_actions.get("brake_land", false))
	if is_on_floor() and vertical_input <= 0.0 and not hover_enabled:
		velocity.y = minf(velocity.y, 0.0)
		_set_flight_state("grounded")
		if vertical_input < 0.0:
			vertical_input = 0.0
	else:
		if is_on_floor() and vertical_input > 0.0:
			velocity.y = maxf(velocity.y, 2.8)
			hover_altitude = global_position.y + 3.2
			_set_flight_state("takeoff")
		var gravity := float(ProjectSettings.get_setting("physics/3d/default_gravity", 16.0))
		if hover_enabled:
			if vertical_input != 0.0:
				hover_altitude += vertical_input * 7.0 * delta
			if landing_requested:
				hover_altitude = maxf(0.6, hover_altitude - 8.0 * delta)
			var spring_force := (hover_altitude - global_position.y) * hover_stiffness
			velocity.y += (spring_force - velocity.y * hover_damping) * delta
			if hover_altitude <= 0.8 and is_on_floor():
				hover_enabled = false
				_set_flight_state("grounded")
			elif flight_state == "takeoff" and global_position.y > 2.0:
				_set_flight_state("hover")
		else:
			velocity.y += (vertical_input * vertical_acceleration - gravity * 0.35) * delta
			if landing_requested and velocity.y < 0.0:
				velocity.y = maxf(velocity.y, -3.0)
			if vertical_input > 0.0:
				_set_flight_state("ascending")
			elif vertical_input < 0.0:
				_set_flight_state("descending")
			elif not is_on_floor():
				_set_flight_state("flight")

	move_and_slide()
	if is_on_ceiling():
		velocity.y = minf(velocity.y, 0.0)
	if get_slide_collision_count() > 0:
		var collision := get_last_slide_collision()
		if collision:
			velocity = velocity.slide(collision.get_normal()) * 0.55
	if desired_direction.length_squared() > 0.02:
		var target_yaw := atan2(-desired_direction.x, -desired_direction.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, 1.0 - exp(-turn_smoothing * delta))
	bank = lerpf(bank, -move_input.x * bank_amount, 1.0 - exp(-5.0 * delta))
	if armor:
		armor.set_flight_pose(flight_state, move_input, boosting, suit_energy)

func _update_aim_and_fire(delta: float) -> void:
	fire_cooldown = maxf(0.0, fire_cooldown - delta)
	var firing := Input.is_action_pressed("fire") or bool(held_actions.get("fire", false))
	if firing and fire_cooldown <= 0.0 and suit_energy >= 4.0:
		if repulsor.fire():
			suit_energy = maxf(0.0, suit_energy - 4.0)
			fire_cooldown = 0.24
			weapon_fired.emit()

func _update_recovery(delta: float) -> void:
	if global_position.y < -8.0:
		recover_to_safe_position()
		return
	if get_slide_collision_count() > 0 and velocity.length() < 0.12:
		recovery_timer += delta
		if recovery_timer > safe_recovery_seconds:
			recover_to_safe_position()
	else:
		recovery_timer = 0.0

func _update_safe_position(delta: float) -> void:
	safe_position_timer += delta
	if safe_position_timer < 1.0:
		return
	safe_position_timer = 0.0
	if global_position.y >= 0.0 and get_slide_collision_count() == 0:
		safe_position = global_position

func toggle_hover() -> void:
	hover_enabled = not hover_enabled
	if hover_enabled:
		hover_altitude = maxf(3.2, global_position.y + (3.2 if is_on_floor() else 0.0))
		_set_flight_state("takeoff" if is_on_floor() else "hover")
	else:
		_set_flight_state("flight")

func _set_flight_state(value: String) -> void:
	if flight_state == value:
		return
	flight_state = value
	flight_state_changed.emit(value)

func _update_safe_position_now() -> void:
	safe_position = global_position

func recover_to_safe_position() -> void:
	global_position = safe_position + Vector3.UP * 0.25
	velocity = Vector3.ZERO
	hover_enabled = false
	recovery_timer = 0.0
	_set_flight_state("recovery")
	GameState.notify("Flight systems recovered")

func set_move_input(value: Vector2) -> void:
	mobile_move = value.limit_length(1.0)

func set_action(action_name: String, pressed: bool) -> void:
	held_actions[action_name] = pressed
	if action_name == "target_lock" and pressed:
		held_actions["_lock_tap"] = true
	if action_name == "recover" and pressed:
		held_actions["_recover_tap"] = true

func set_look_input(value: Vector2) -> void:
	if camera_rig:
		camera_rig.add_touch_look(value)

func clear_touch_input() -> void:
	mobile_move = Vector2.ZERO
	_clear_actions()

func _clear_actions() -> void:
	for action_name in ["ascend", "descend", "boost", "hover", "fire", "target_lock", "brake_land"]:
		held_actions[action_name] = false
	held_actions["_lock_tap"] = false
	held_actions["_recover_tap"] = false
	mobile_move = Vector2.ZERO

func get_bank_amount() -> float:
	return bank

func get_forward_speed() -> float:
	return Vector2(velocity.x, velocity.z).length()
