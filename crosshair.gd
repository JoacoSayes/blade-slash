extends Control

@export var tamaño: float = 10.0       # largo de cada línea del crosshair
@export var grosor: float = 2.0        # grosor de las líneas
@export var espacio_central: float = 4.0  # hueco vacío en el medio
@export var color: Color = Color.WHITE

func _ready() -> void:
	# Importante: que NO bloquee el mouse, es solo decorativo
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var centro := size / 2.0

	# Línea horizontal (izquierda y derecha, con hueco en el medio)
	draw_line(centro - Vector2(tamaño, 0), centro - Vector2(espacio_central, 0), color, grosor)
	draw_line(centro + Vector2(espacio_central, 0), centro + Vector2(tamaño, 0), color, grosor)

	# Línea vertical (arriba y abajo, con hueco en el medio)
	draw_line(centro - Vector2(0, tamaño), centro - Vector2(0, espacio_central), color, grosor)
	draw_line(centro + Vector2(0, espacio_central), centro + Vector2(0, tamaño), color, grosor)
