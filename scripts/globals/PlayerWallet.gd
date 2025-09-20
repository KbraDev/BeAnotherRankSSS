# PlayerWallet.gd
extends Node
class_name PlayerWallet

signal coins_changed

# Diccionario dinámico, inicializado con 0
var coins: Dictionary = {
	"coin_bronze": 0,
	"coin_silver": 0,
	"coin_gold": 0
}

func add_coins(coin_id: String, amount: int) -> void:
	if not coins.has(coin_id):
		coins[coin_id] = 0
	coins[coin_id] += amount
	emit_signal("coins_changed")

func remove_coins(coin_id: String, amount: int) -> bool:
	if coins.get(coin_id, 0) >= amount:
		coins[coin_id] -= amount
		emit_signal("coins_changed")
		return true
	return false

func get_coin_amount(coin_id: String) -> int:
	return coins.get(coin_id, 0)
