extends Node

# 🔹 Diccionario que asocia rutas con nombres legibles
const SCENE_NAMES := {
	"res://scenes/world/location/olid_town/olid_town.tscn": "Pueblo Olid",
	"res://scenes/world/location/olid_town/InOlidTownScenes/GuildOlidTown/guild_olid_town.tscn" : "Gremio de pueblo Olid",
	"res://scenes/world/location/olid_town/InOlidTownScenes/fathers_home.tscn": "Casa de Auren",
	"res://scenes/world/zones/olidForest/OlidForest.tscn": "Bosque Olid",
	"res://scenes/world/zones/milistrail/milis_trail.tscn": "Sendero de Milis",
	"res://scenes/world/zones/OlidRuins/templeOlid.tscn": "Ruinas de Olid",
	"res://scenes/world/location/MilisCity/city_milis.tscn" : "Pueblo Milis",
	"res://scenes/world/location/MilisCity/milis_guild.tscn" : "Gremio del pueblo Milis"
}

# 🔹 Devuelve un nombre legible a partir de una ruta
static func get_display_name(scene_path: String) -> String:
	if SCENE_NAMES.has(scene_path):
		return SCENE_NAMES[scene_path]
	# fallback: si no existe, muestra solo el nombre del archivo sin extensión
	return scene_path.get_file().get_basename().capitalize()
