extends Node2D

@onready var player := $player
@onready var world_container := $WorldContainer
@onready var active_mission_menu = $HUD/ActiveMissionsMenu
@onready var floating_notification = $HUD/FloatingNotiification
@onready var notif := get_node("HUD/FloatingNotiification")
@onready var transition_overlay := $HUD/TransitionOverlay
@onready var transition_anim := $HUD/TransitionOverlay/AnimationPlayer

var current_world: Node = null
var _thread := Thread.new()
var _next_scene: PackedScene = null
var _preloaded_scenes: Dictionary = {}

func _ready():
	var hud = $HUD
	hud.set_player(player)

	var inventory_ui = $HUD/InventoryUI
	player.connect("inventory_updated", inventory_ui.update_ui)
	inventory_ui.update_ui(player.inventory)

	current_world = world_container.get_child(0)
	_preload_connected_scenes(current_world)

func change_world(scene_path: String, target_marker_name: String) -> void:
	transition_anim.play("fade_out")
	await transition_anim.animation_finished

	for child in world_container.get_children():
		child.queue_free()
	await get_tree().process_frame

	if _preloaded_scenes.has(scene_path):
		_next_scene = _preloaded_scenes[scene_path]
	else:
		_next_scene = null
		_thread.start(Callable(self, "_load_scene_threaded").bind(scene_path))
		await _thread.wait_to_finish()

	if _next_scene == null:
		print("❌ No se pudo cargar la escena:", scene_path)
		return

	var new_world = _next_scene.instantiate()
	_remove_duplicate_players(new_world) # 🔥 AÑADIDO: prevenir duplicados
	world_container.add_child(new_world)
	current_world = new_world

	var marker = _find_marker_in(current_world, target_marker_name)
	if marker:
		player.global_position = marker.global_position
	else:
		print("❌ Marker no encontrado:", target_marker_name)

	transition_anim.play("fade_in")
	await transition_anim.animation_finished

	for s in get_tree().get_nodes_in_group("slime"):
		s.queue_free()

	_preload_connected_scenes(current_world)

	for checkpoint in current_world.get_tree().get_nodes_in_group("checkpoint"):
		checkpoint.connect("checkpoint_reached", Callable(player, "update_checkpoint"))

func _remove_duplicate_players(node: Node):
	if node.name == "player":
		print("🧹 Eliminando player duplicado de la escena cargada")
		node.queue_free()
	for child in node.get_children():
		_remove_duplicate_players(child)

func _preload_connected_scenes(world: Node) -> void:
	var meta = world.get_node_or_null("SceneMeta")
	if meta and "portal_data" in meta and meta.portal_data:
		for path in meta.portal_data.connected_scenes:
			if not _preloaded_scenes.has(path):
				print("📦 Precargando escena vecina:", path)
				_preload_scene_async(path)

func _preload_scene_async(path: String) -> void:
	var thread := Thread.new()
	thread.start(Callable(self, "_threaded_preload").bind(path))

func _threaded_preload(path: String) -> void:
	var scene = load(path)
	if scene:
		_preloaded_scenes[path] = scene

func _load_scene_threaded(scene_path: String) -> void:
	_next_scene = load(scene_path)

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("open_mission"):
		if not active_mission_menu.visible:
			active_mission_menu.open()
		else:
			active_mission_menu.close()

func _find_marker_in(node: Node, name: String) -> Node:
	for child in node.get_children():
		if child.name == name:
			return child
		var found = _find_marker_in(child, name)
		if found != null:
			return found
	return null

func fade_to_black():
	print("🎬 Ejecutando fundido a negro")
	transition_anim.play("fade_out")

func load_game_state(save_data: Dictionary) -> void:
	var scene_path = save_data.get("scene_path", "")
	if scene_path == "":
		print("❌ No se especificó ninguna escena.")
		return

	transition_anim.play("fade_out")
	await transition_anim.animation_finished

	for child in world_container.get_children():
		child.queue_free()
	await get_tree().process_frame

	var packed_scene = load(scene_path)
	if packed_scene == null:
		print("❌ No se pudo cargar la escena guardada.")
		return

	var new_world = packed_scene.instantiate()
	_remove_duplicate_players(new_world) # 🔥 AÑADIDO también aquí
	world_container.add_child(new_world)
	current_world = new_world

	var pos = save_data["player"].get("position", [0, 0])
	player.global_position = Vector2(pos[0], pos[1])
	player.load_from_save(save_data["player"])

	transition_anim.play("fade_in")
	await transition_anim.animation_finished

	_preload_connected_scenes(current_world)

	for checkpoint in current_world.get_tree().get_nodes_in_group("checkpoint"):
		checkpoint.connect("checkpoint_reached", Callable(player, "update_checkpoint"))

	print("📂 Restaurando desde escena:", scene_path)
	if packed_scene == null:
		print("❌ No se pudo cargar la escena:", scene_path)
		return

	print("📂 Restaurando desde escena:", scene_path)
	print("📍 Posición exacta:", save_data["player"]["position"])

func get_current_world_scene_path() -> String:
	return current_world.scene_file_path
