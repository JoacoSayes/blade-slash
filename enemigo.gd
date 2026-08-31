extends CharacterBody3D

# ------------------------
# CONFIGURACIÓN DEL ENEMIGO
# ------------------------
@export var velocidad: float = 3.5
@export var vida_maxima: int = 30
@export var daño_contacto: int = 10
@export var gravedad: float = 20.0
@export var distancia_ataque: float = 1.5  # qué tan cerca tiene que estar para pegar
@export var tiempo_entre_ataques: float = 1.0

# Arrastrá acá la(s) escena(s) de item que puede soltar este enemigo
@export var escenas_items: Array[PackedScene] = []
@export var probabilidad_drop: float = 0.4  # 0.4 = 40% de chance

# Arrastrá acá la escena EfectoImpacto.tscn (podés usar otra variante para muerte)
@export var escena_efecto_muerte: PackedScene

# Se emite cuando el enemigo muere, el director_oleadas.gd escucha esto
signal murio

var vida_actual: int
var jugador: Node3D = null
var puede_atacar: bool = true

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D

func _ready() -> void:
	vida_actual = vida_maxima
	# Buscamos al jugador por grupo (asegurate de agregar el nodo Player
	# al grupo "jugador" desde el Inspector, pestaña "Grupos")
	jugador = get_tree().get_first_node_in_group("jugador")

	if jugador == null:
		push_warning("No se encontró ningún nodo en el grupo 'jugador'")

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravedad * delta

	if jugador == null:
		move_and_slide()
		return

	nav_agent.target_position = jugador.global_position

	var distancia_al_jugador := global_position.distance_to(jugador.global_position)

	if distancia_al_jugador > distancia_ataque:
		# Perseguir: nos movemos hacia el siguiente punto del camino calculado
		var siguiente_punto: Vector3 = nav_agent.get_next_path_position()
		var direccion := (siguiente_punto - global_position)
		direccion.y = 0  # ignoramos diferencia de altura para no "volar"
		direccion = direccion.normalized()

		velocity.x = direccion.x * velocidad
		velocity.z = direccion.z * velocidad

		# Rotamos el enemigo para que mire hacia donde camina
		if direccion.length() > 0.1:
			look_at(global_position + direccion, Vector3.UP)
	else:
		# Ya está en rango de ataque: se detiene y ataca
		velocity.x = 0
		velocity.z = 0
		intentar_atacar()

	move_and_slide()

func intentar_atacar() -> void:
	if not puede_atacar:
		return

	if jugador.has_method("recibir_daño"):
		jugador.recibir_daño(daño_contacto)

	puede_atacar = false
	await get_tree().create_timer(tiempo_entre_ataques).timeout
	puede_atacar = true

# Llamado desde afuera (por ejemplo, desde proyectil.gd) cuando recibe daño
func recibir_daño(cantidad: int) -> void:
	vida_actual -= cantidad
	print("Enemigo recibió %d de daño. Vida restante: %d" % [cantidad, vida_actual])

	if vida_actual <= 0:
		morir()

func morir() -> void:
	if escena_efecto_muerte != null:
		var efecto = escena_efecto_muerte.instantiate()
		get_tree().current_scene.add_child(efecto)
		efecto.global_position = global_position

	intentar_soltar_item()
	murio.emit()
	queue_free()

func intentar_soltar_item() -> void:
	if escenas_items.is_empty():
		return

	if randf() > probabilidad_drop:
		return  # no hubo suerte esta vez

	var escena: PackedScene = escenas_items[randi() % escenas_items.size()]
	var item = escena.instantiate()
	get_tree().current_scene.add_child(item)
	item.global_position = global_position
