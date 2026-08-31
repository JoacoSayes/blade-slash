extends Control

@onready var boton_inicio: Button = $Contenedor/BotonInicio
@onready var boton_salir: Button = $Contenedor/BotonSalir

# Ajustá esta ruta según dónde tengas guardado tu Main.tscn en el proyecto
const ESCENA_JUEGO := "res://main.tscn"

func _ready() -> void:
	boton_inicio.pressed.connect(_on_boton_inicio_pressed)
	boton_salir.pressed.connect(_on_boton_salir_pressed)

	# Por las dudas venías de una partida anterior con el mouse capturado
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_boton_inicio_pressed() -> void:
	get_tree().change_scene_to_file(ESCENA_JUEGO)

func _on_boton_salir_pressed() -> void:
	get_tree().quit()
