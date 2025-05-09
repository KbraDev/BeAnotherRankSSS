extends Panel ## InventorySlotUI

func set_item(icon_texture: Texture2D, amount: int):
	$icon.texture = icon_texture
	$amount.text = str(amount) if amount > 0 else ""
