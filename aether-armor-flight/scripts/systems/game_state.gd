extends Node

signal state_changed(state_name: String)
signal energy_changed(current: float, maximum: float)
signal score_changed(score: int)
signal challenge_changed(progress: int, total: int, elapsed: float)
signal target_changed(target: Node3D)
signal message_requested(text: String)

enum State { MENU, PLAYING, PAUSED, COMPLETE }

var state: State = State.MENU
var mode: String = "free_flight"
var score: int = 0
var challenge_progress: int = 0
var challenge_total: int = 0
var elapsed_time: float = 0.0
var suit_energy: float = 100.0
var target: Node3D

func _ready() -> void:
	_register_action("move_forward", KEY_W)
	_register_action("move_back", KEY_S)
	_register_action("move_left", KEY_A)
	_register_action("move_right", KEY_D)
	_register_action("ascend", KEY_SPACE)
	_register_action("descend", KEY_CTRL)
	_register_action("boost", KEY_SHIFT)
	_register_action("hover", KEY_H)
	_register_action("fire", KEY_NONE, MOUSE_BUTTON_LEFT)
	_register_action("target_lock", KEY_NONE, MOUSE_BUTTON_RIGHT)
	_register_action("brake_land", KEY_B)
	_register_action("pause_game", KEY_ESCAPE)
	_register_action("recover", KEY_R)

func _register_action(action_name: String, keycode: Key, mouse_button: MouseButton = MOUSE_BUTTON_NONE) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	if keycode != KEY_NONE:
		var key_event := InputEventKey.new()
		key_event.physical_keycode = keycode
		if not InputMap.action_has_event(action_name, key_event):
			InputMap.action_add_event(action_name, key_event)
	if mouse_button != MOUSE_BUTTON_NONE:
		var mouse_event := InputEventMouseButton.new()
		mouse_event.button_index = mouse_button
		if not InputMap.action_has_event(action_name, mouse_event):
			InputMap.action_add_event(action_name, mouse_event)

func start_session(session_mode: String) -> void:
	mode = session_mode
	score = 0
	challenge_progress = 0
	challenge_total = 0
	elapsed_time = 0.0
	suit_energy = 100.0
	target = null
	state = State.PLAYING
	score_changed.emit(score)
	energy_changed.emit(suit_energy, 100.0)
	state_changed.emit("playing")

func set_state(next_state: State) -> void:
	if state == next_state:
		return
	state = next_state
	state_changed.emit(state_name())

func state_name() -> String:
	match state:
		State.MENU:
			return "menu"
		State.PLAYING:
			return "playing"
		State.PAUSED:
			return "paused"
		State.COMPLETE:
			return "complete"
	return "menu"

func is_playing() -> bool:
	return state == State.PLAYING

func set_energy(value: float) -> void:
	suit_energy = clampf(value, 0.0, 100.0)
	energy_changed.emit(suit_energy, 100.0)

func add_score(amount: int) -> void:
	score = maxi(0, score + amount)
	score_changed.emit(score)

func set_challenge(progress: int, total: int, time_value: float) -> void:
	challenge_progress = progress
	challenge_total = total
	elapsed_time = time_value
	challenge_changed.emit(progress, total, time_value)

func set_target(value: Node3D) -> void:
	target = value
	target_changed.emit(value)

func notify(text: String) -> void:
	message_requested.emit(text)

func clear_transient_input() -> void:
	for action_name in ["ascend", "descend", "boost", "fire", "target_lock", "brake_land", "recover"]:
		Input.action_release(action_name)
