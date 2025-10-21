extends MissionResource
class_name CollectMission

@export var item_required: String      # Nombre interno del ítem (de ItemDatabase)
@export var amount_required: int = 1   # Cantidad total a recolectar
@export var track_progress: bool = true  # Si muestra o no el progreso en pantalla
