extends Control
class_name AbilityTooltip

@onready var title_label: RichTextLabel = $Panel/TitleLabel
@onready var desc_label: RichTextLabel = $Panel/DescriptionLabel
@onready var usage_label: RichTextLabel = $Panel/UsageLabel
@onready var usage_icon: TextureRect = $Panel/Icon


func set_content(
	title: String,
	description: String,
	usage: String,
	usage_icon_texture: Texture2D
) -> void:
	title_label.text = title
	desc_label.text = description
	usage_label.text = usage

	if usage_icon_texture:
		usage_icon.texture = usage_icon_texture
		usage_icon.visible = true
	else:
		usage_icon.visible = false

	# Esperar 1 frame para que el layout se actualice
	await get_tree().process_frame

	custom_minimum_size = (
		title_label.get_combined_minimum_size()
		+ desc_label.get_combined_minimum_size()
		+ usage_label.get_combined_minimum_size()
		+ Vector2(24, 24)
	)
