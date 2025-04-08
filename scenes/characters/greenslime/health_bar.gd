extends TextureProgressBar ## Barra de vide Slime

var hide_delay := 6.0 # Tiempo que se queda visible
var hide_timer := 0.0 

func _ready() -> void:
	hide() # barra oculta
	
func show_for_a_while():
	show()
	hide_timer = hide_delay
	
func _process(delta: float) -> void:
	if hide_timer > 0 :
		hide_timer -= delta
		if hide_timer <= 0:
			hide()
			
