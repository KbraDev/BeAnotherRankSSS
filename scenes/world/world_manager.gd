extends Node2D

const NEW_GAME_SCENE := "res://scenes/world/location/olid_town/InOlidTownScenes/fathers_home.tscn"
const NEW_GAME_SPAWN := "SpawnPoint"
const DEBUG_SLOW_SCENE := "res://scenes/world/location/olid_town/olid_town.tscn"


@onready var player := $player
@onready var world_container := $WorldContainer
@onready var active_mission_menu = $HUD/ActiveMissionsMenu
@onready var floating_notification = $HUD/FloatingNotiification
@onready var notif := get_node("HUD/FloatingNotiification")
@onready var transition_overlay := $Transition/TransitionOverlay
@onready var transition_anim := $Transition/TransitionOverlay/AnimationPlayer

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

	if inventory_ui:
		inventory_ui.player = player

	# ⚠️ No asumir que existe un mundo cargado
	current_world = null

func start_new_game() -> void:
	var save_data := {
		"scene_path": NEW_GAME_SCENE,
		"is_new_game": true
	}

	await load_game_state(save_data)


func _on_world_activated(world: Node) -> void:
	current_world = world

	# Precargar escenas vecinas
	_preload_connected_scenes(world)

	# Conectar checkpoints
	for checkpoint in world.get_tree().get_nodes_in_group("checkpoint"):
		checkpoint.connect(
			"checkpoint_reached",
			Callable(player, "update_checkpoint")
		)

func change_world(scene_path: String, target_marker_name: String) -> void:
	var overlay: Node = null
	if Engine.has_singleton("TransitionOverlay"):
		overlay = Engine.get_singleton("TransitionOverlay")
	elif get_tree().root.has_node("TransitionOverlay"):
		overlay = get_tree().root.get_node("TransitionOverlay")

	# --- Fade Out ---
	if overlay:
		await overlay.fade_out()
	elif transition_anim and transition_anim.has_animation("fade_out"):
		transition_anim.play("fade_out")
		await transition_anim.animation_finished

	# --- Limpiar mundos anteriores ---
	for child in world_container.get_children():
		child.queue_free()
	await get_tree().process_frame

	# --- Carga asíncrona ---
	var new_world: Node = null
	if _preloaded_scenes.has(scene_path):
		new_world = _preloaded_scenes[scene_path].instantiate()
	else:
		new_world = await _load_scene_async(scene_path)

	if not new_world:
		push_error("❌ No se pudo cargar el mundo.")
		return

	_remove_duplicate_players(new_world)
	world_container.add_child(new_world)
	await get_tree().process_frame

	player.update_tilemap_reference()

	# --- Posición del jugador ---
	var marker = _find_marker_in(new_world, target_marker_name)
	if marker:
		player.global_position = marker.global_position

	# --- Activar mundo ---
	_on_world_activated(new_world)

	# --- Fade In ---
	if overlay:
		await overlay.fade_in()
	elif transition_anim and transition_anim.has_animation("fade_in"):
		transition_anim.play("fade_in")
		await transition_anim.animation_finished


func _remove_duplicate_players(node: Node):
	if node.name == "player":
		node.queue_free()
	for child in node.get_children():
		_remove_duplicate_players(child)

func _preload_connected_scenes(world: Node) -> void:
	var meta = world.get_node_or_null("SceneMeta")
	if meta and "portal_data" in meta and meta.portal_data:
		for path in meta.portal_data.connected_scenes:
			if not _preloaded_scenes.has(path):
				_preload_scene_async(path)

func _preload_scene_async(path: String) -> void:
	var thread := Thread.new()
	thread.start(Callable(self, "_threaded_preload").bind(path))

func _threaded_preload(path: String) -> void:
	var scene = load(path)
	if scene:
		_preloaded_scenes[path] = scene
	else:
		return

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
	transition_anim.play("fade_out")

func load_game_state(save_data: Dictionary) -> void:
	# --- Restaurar FLAGS GLOBALES ---
	if save_data.has("flags"):
		GameState.restore_flags(save_data["flags"])

	var scene_path = save_data.get("scene_path", "")
	if scene_path == "":
		push_error("❌ No se proporcionó scene_path en save_data.")
		return

	# --- Fade Out ---
	transition_anim.play("fade_out")
	await transition_anim.animation_finished

	# --- Limpiar mundos anteriores ---
	for child in world_container.get_children():
		child.queue_free()
	await get_tree().process_frame

	# --- Cargar mundo ---
	var new_world = await _load_scene_async(scene_path)
	if not new_world:
		push_error("❌ No se pudo cargar el mundo.")
		return

	_remove_duplicate_players(new_world)
	world_container.add_child(new_world)
	await get_tree().process_frame

	player.update_tilemap_reference()

	# --- Posición del jugador ---
	if save_data.has("player"):
		var player_data = save_data["player"]

		if save_data.get("is_new_game", false):
			var spawn = _find_marker_in(new_world, "SpawnPoint")
			player.global_position = spawn.global_position if spawn else Vector2.ZERO
		else:
			SaveManager.restore_player_data(player, player_data)
	else:
		var spawn = _find_marker_in(new_world, "SpawnPoint")
		player.global_position = spawn.global_position if spawn else Vector2.ZERO

	# --- Restaurar misiones ---
	if save_data.has("missions"):
		SaveManager.restore_mission_data(save_data["missions"])
		player.emit_signal("inventory_updated", player.inventory)

	# --- Activar mundo ---
	_on_world_activated(new_world)

	# --- Fade In ---
	transition_anim.play("fade_in")
	await transition_anim.animation_finished



# --- carga asincrona ---

func _load_scene_async(scene_path: String) -> Node:
	var debug := scene_path == DEBUG_SLOW_SCENE
	var t_start := Time.get_ticks_msec()

	if debug:
		print("\n🟡 [LOAD] Iniciando carga:", scene_path)

	# Solicitar carga si no existe
	var status := ResourceLoader.load_threaded_get_status(scene_path)
	if status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		if debug:
			print("🟡 [LOAD] Solicitando load_threaded_request")
		ResourceLoader.load_threaded_request(scene_path)

	# Esperar carga
	while true:
		status = ResourceLoader.load_threaded_get_status(scene_path)
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			break
		if status == ResourceLoader.THREAD_LOAD_FAILED:
			push_error("❌ Fallo al cargar escena: " + scene_path)
			return null
		await get_tree().process_frame

	var t_loaded := Time.get_ticks_msec()
	if debug:
		print("🟢 [LOAD] PackedScene cargado en",
			t_loaded - t_start, "ms")

	# Instanciación (ESTO suele ser el cuello de botella)
	var packed := ResourceLoader.load_threaded_get(scene_path)
	if packed is PackedScene:
		var t_inst_start := Time.get_ticks_msec()
		var instance = packed.instantiate()
		var t_inst_end := Time.get_ticks_msec()

		if debug:
			print("🟠 [LOAD] Instanciación tardó",
				t_inst_end - t_inst_start, "ms")
			print("🟢 [LOAD] Total:",
				t_inst_end - t_start, "ms")

		return instance

	push_error("❌ El recurso no es PackedScene: " + scene_path)
	return null
