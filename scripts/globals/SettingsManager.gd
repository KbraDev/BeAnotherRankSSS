extends Node

const CONFIG_PATH := "user://settings.cfg"

const SECTION_AUDIO := "audio"
const KEY_MUSIC := "music_volume"
const KEY_SFX := "sfx_volume"

var config := ConfigFile.new()

var music_bus := AudioServer.get_bus_index("Music")
var sfx_bus := AudioServer.get_bus_index("SFX")


func _ready() -> void:
	load_settings()
	apply_audio_settings()


func load_settings() -> void:
	var err := config.load(CONFIG_PATH)

	if err != OK:
		config.set_value(SECTION_AUDIO, KEY_MUSIC, 1.0)
		config.set_value(SECTION_AUDIO, KEY_SFX, 1.0)
		save_settings()


func save_settings() -> void:
	config.save(CONFIG_PATH)


func apply_audio_settings() -> void:
	if music_bus != -1:
		var music_value = config.get_value(SECTION_AUDIO, KEY_MUSIC, 1.0)
		AudioServer.set_bus_volume_db(music_bus, linear_to_db(music_value))

	if sfx_bus != -1:
		var sfx_value = config.get_value(SECTION_AUDIO, KEY_SFX, 1.0)
		AudioServer.set_bus_volume_db(sfx_bus, linear_to_db(sfx_value))


func set_music_volume(value: float) -> void:
	config.set_value(SECTION_AUDIO, KEY_MUSIC, value)
	save_settings()
	apply_audio_settings()


func set_sfx_volume(value: float) -> void:
	config.set_value(SECTION_AUDIO, KEY_SFX, value)
	save_settings()
	apply_audio_settings()


func get_music_volume() -> float:
	return config.get_value(SECTION_AUDIO, KEY_MUSIC, 1.0)


func get_sfx_volume() -> float:
	return config.get_value(SECTION_AUDIO, KEY_SFX, 1.0)
