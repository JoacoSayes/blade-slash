extends Node3D

# Avisa cuándo empieza una nueva oleada, para que la UI (paso 6) la muestre
signal oleada_iniciada(numero: int)

# ------------------------
# CONFIGURACIÓN DE OLEADAS
# ------------------------

# Arrastrá acá la(s) escena(s) de enemigos que quieras que aparezcan
@export var escenas_enemigos: Array[PackedScene] = []

# Cuántos enemigos aparecen en la oleada 1
@export var enemigos_oleada_inicial: int = 3

# Cuántos enemigos MÁS se suman por cada oleada que pasa
@export var incremento_por_oleada: int = 2

# Tiempo de descanso entre que termina una oleada y empieza la siguiente
@export var tiempo_entre_oleadas: float = 5.0

# Tiempo entre cada spawn individual dentro de la misma oleada
# (para que no aparezcan todos los enemigos exactamente al mismo tiempo)
@export var tiempo_entre_spawns: float = 0.5

var oleada_actual: int = 0
var enemigos_vivos: int = 0
var oleada_en_curso: bool = false

@onready var puntos_spawn: Array[Node] = $PuntosSpawn.get_children()

func _ready() -> void:
	if puntos_spawn.is_empty():
		push_warning("No hay puntos de spawn asignados en el grupo PuntosSpawn")
	iniciar_siguiente_oleada()

func iniciar_siguiente_oleada() -> void:
	oleada_actual += 1
	oleada_en_curso = true

	var cantidad := enemigos_oleada_inicial + (incremento_por_oleada * (oleada_actual - 1))
	print("--- Empieza la oleada %d con %d enemigos ---" % [oleada_actual, cantidad])
	oleada_iniciada.emit(oleada_actual)

	for i in range(cantidad):
		spawnear_enemigo()
		# Esperamos un poquito entre cada spawn individual
		await get_tree().create_timer(tiempo_entre_spawns).timeout

func spawnear_enemigo() -> void:
	if escenas_enemigos.is_empty() or puntos_spawn.is_empty():
		return

	# Elegimos un enemigo al azar de la lista (podés tener varios tipos)
	var escena: PackedScene = escenas_enemigos[randi() % escenas_enemigos.size()]
	var enemigo = escena.instantiate()

	# Elegimos un punto de spawn al azar
	var punto: Node3D = puntos_spawn[randi() % puntos_spawn.size()]

	add_child(enemigo)
	enemigo.global_position = punto.global_position

	enemigos_vivos += 1

	# Nos conectamos a la señal de muerte del enemigo (la creamos en el paso 4)
	if enemigo.has_signal("murio"):
		enemigo.murio.connect(_on_enemigo_murio)

func _on_enemigo_murio() -> void:
	enemigos_vivos -= 1
	print("Enemigos restantes: ", enemigos_vivos)

	if enemigos_vivos <= 0 and oleada_en_curso:
		oleada_en_curso = false
		print("Oleada %d completada. Siguiente en %.1f segundos..." % [oleada_actual, tiempo_entre_oleadas])
		await get_tree().create_timer(tiempo_entre_oleadas).timeout
		iniciar_siguiente_oleada()
