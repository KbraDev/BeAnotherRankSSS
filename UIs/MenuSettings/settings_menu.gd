extends Control

signal request_back

@onready var music_slider: HSlider = $Panel/VBoxContainer/MusicRow/HSliderMusic
@onready var sfx_slider: HSlider = $Panel/VBoxContainer/SfxRow/HSliderSFX


func _ready() -> void:
	# Sincronizar sliders con valores guardados
	_sync_sliders_with_settings()

	# Conectar callbacks
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)


# --- Sincronizar sliders con SettingsManager ---
func _sync_sliders_with_settings() -> void:
	music_slider.set_block_signals(true)
	sfx_slider.set_block_signals(true)

	music_slider.value = SettingsManager.get_music_volume()
	sfx_slider.value = SettingsManager.get_sfx_volume()

	music_slider.set_block_signals(false)
	sfx_slider.set_block_signals(false)


# --- Callbacks ---
func _on_music_changed(value: float) -> void:
	SettingsManager.set_music_volume(value)


func _on_sfx_changed(value: float) -> void:
	SettingsManager.set_sfx_volume(value)


# --- Salir ---
func _on_back_button_pressed() -> void:
	request_back.emit()
