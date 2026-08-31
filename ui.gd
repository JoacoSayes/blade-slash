extends CanvasLayer

# Arrastrá acá el nodo Player y DirectorOleadas desde el Inspector
@export var jugador: Node3D
@export var director: Node3D

@onready var barra_vida: ProgressBar = $Contenedor/BarraVida
@onready var label_oleada: Label = $Contenedor/LabelOleada
@onready var panel_game_over: Control = $Contenedor/PanelGameOver
@onready var boton_reintentar: Button = $Contenedor/PanelGameOver/BotonReintentar

func _ready() -> void:
	panel_game_over.visible = false
	boton_reintentar.pressed.connect(_on_boton_reintentar_pressed)

	if jugador:
		jugador.vida_cambio.connect(_on_vida_cambio)
		jugador.murio.connect(_on_jugador_murio)
	else:
		push_warning("Falta asignar 'jugador' en el Inspector de la UI")

	if director:
		director.oleada_iniciada.connect(_on_oleada_iniciada)
	else:
		push_warning("Falta asignar 'director' en el Inspector de la UI")

func _on_vida_cambio(vida_actual: int, vida_maxima: int) -> void:
	barra_vida.max_value = vida_maxima
	barra_vida.value = vida_actual

func _on_oleada_iniciada(numero: int) -> void:
	label_oleada.text = "Oleada %d" % numero

func _on_jugador_murio() -> void:
	panel_game_over.visible = true
	# Liberamos el mouse para que se pueda hacer clic en el botón
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_boton_reintentar_pressed() -> void:
	get_tree().reload_current_scene()
