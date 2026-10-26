extends Node

const SETTINGS_PATH := "user://settings.cfg"
const RECORDS_PATH := "user://records.cfg"

var settings: Dictionary = {
	"camera_sensitivity": 0.12,
	"graphics_quality": 1,
}
var records: Dictionary = {}

func _ready() -> void:
	load_all()

func load_all() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) == OK:
		settings["camera_sensitivity"] = clampf(float(config.get_value("settings", "camera_sensitivity", 0.12)), 0.03, 0.4)
		settings["graphics_quality"] = clampi(int(config.get_value("settings", "graphics_quality", 1)), 0, 2)
	var record_config := ConfigFile.new()
	if record_config.load(RECORDS_PATH) == OK:
		records = record_config.get_value("records", "best_times", {})

func set_camera_sensitivity(value: float) -> void:
	settings["camera_sensitivity"] = clampf(value, 0.03, 0.4)
	save_settings()

func set_graphics_quality(value: int) -> void:
	settings["graphics_quality"] = clampi(value, 0, 2)
	save_settings()

func save_settings() -> void:
	var config := ConfigFile.new()
	for key in settings:
		config.set_value("settings", key, settings[key])
	var result := config.save(SETTINGS_PATH)
	if result != OK:
		push_error("Could not save settings (error %d)." % result)

func record_challenge(challenge_name: String, elapsed: float) -> bool:
	var previous := float(records.get(challenge_name, INF))
	if elapsed >= previous:
		return false
	records[challenge_name] = elapsed
	var config := ConfigFile.new()
	config.set_value("records", "best_times", records)
	var result := config.save(RECORDS_PATH)
	if result != OK:
		push_error("Could not save challenge record (error %d)." % result)
	return true

func best_time(challenge_name: String) -> float:
	return float(records.get(challenge_name, -1.0))
