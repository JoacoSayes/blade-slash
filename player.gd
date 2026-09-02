extends CharacterBody3D

# ------------------------
# VARIABLES CONFIGURABLES
# ------------------------
@export var velocidad: float = 6.0
@export var multiplicador_correr: float = 1.5
@export var fuerza_salto: float = 8.0
@export var sensibilidad_mouse: float = 0.003
@export var gravedad: float = 20.0

@export var vida_maxima: int = 100
@export var daño_base: int = 10

# Bonos acumulados por los items recogidos (empiezan en 0)
var bono_daño: float = 0.0
var bono_velocidad: float = 0.0

# Límites para que la cámara no gire infinito hacia arriba/abajo
@export var limite_pitch_arriba: float = deg_to_rad(70)
@export var limite_pitch_abajo: float = deg_to_rad(-40)

@onready var spring_arm: SpringArm3D = $SpringArm3D
@onready var camara: Camera3D = $SpringArm3D/Camera3D
@onready var punto_disparo: Marker3D = $PuntoDisparo
@onready var animation_player: AnimationPlayer = $ModeloJugador/AnimationPlayer

# Arrastrá aquí la escena Proyectil.tscn desde el Inspector una vez creada
@export var escena_proyectil: PackedScene

# Arrastrá aquí la escena AtaqueMelee.tscn
@export var escena_ataque_melee: PackedScene
@export var distancia_melee: float = 1.5
@export var altura_melee: float = 0.0
@export var cooldown_melee: float = 0.5

var puede_atacar_melee: bool = true

# Se emiten para que la UI (paso 6) pueda escuchar sin que este script
# necesite saber nada de cómo se dibuja la vida en pantalla
signal vida_cambio(vida_actual: int, vida_maxima: int)
signal murio

var pitch: float = 0.0  # rotación vertical de la cámara
var vida_actual: int
var esta_vivo: bool = true
var mapa_animaciones: Dictionary = {}
@export var duracion_transicion_animacion: float = 0.2

func _ready() -> void:
	# Captura el mouse dentro de la ventana del juego
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	vida_actual = vida_maxima
	# Avisamos el valor inicial para que la UI arranque mostrando la barra llena
	vida_cambio.emit(vida_actual, vida_maxima)

	# --- DEBUG TEMPORAL ---
	if animation_player == null:
		print("DEBUG: animation_player es NULL, la ruta $ModeloJugador/AnimationPlayer no encontró nada")
	else:
		var lista := animation_player.get_animation_list()
		print("DEBUG: animation_player encontrado. Animaciones disponibles: ", lista)

		# Cada nombre puede venir con prefijo de biblioteca (ej: "walk_library/Walk").
		# Armamos un mapa "Walk" -> "walk_library/Walk" para no depender de
		# saber el prefijo exacto de antemano.
		for nombre_completo in lista:
			var nombre_corto: String = nombre_completo
			if "/" in nombre_completo:
				nombre_corto = nombre_completo.get_slice("/", 1)
			mapa_animaciones[nombre_corto] = nombre_completo

		print("DEBUG: mapa de animaciones resuelto: ", mapa_animaciones)

func _unhandled_input(event: InputEvent) -> void:
	if not esta_vivo:
		return

	# Rotación de cámara con el mouse
	if event is InputEventMouseMotion:
		# Rotamos el PERSONAJE en el eje Y (izquierda/derecha)
		rotate_y(-event.relative.x * sensibilidad_mouse)

		# Rotamos el SPRING ARM (la cámara) en el eje X (arriba/abajo)
		pitch -= event.relative.y * sensibilidad_mouse
		pitch = clamp(pitch, limite_pitch_abajo, limite_pitch_arriba)
		spring_arm.rotation.x = pitch

	# Presionar ESC para liberar el mouse (útil para debug)
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	# Disparo con clic izquierdo
	if event.is_action_pressed("disparar"):
		disparar()

	# Ataque melee con la tecla/botón asignado
	if event.is_action_pressed("atacar_melee"):
		atacar_melee()

func disparar() -> void:
	if escena_proyectil == null:
		push_warning("Falta asignar 'escena_proyectil' en el Inspector")
		return

	var proyectil = escena_proyectil.instantiate()
	get_tree().current_scene.add_child(proyectil)

	# Lo posicionamos donde está el punto de disparo (frente a la cámara)
	proyectil.global_position = punto_disparo.global_position

	# La dirección real se calcula apuntando hacia el punto exacto que mira
	# la cámara (con un raycast), no copiando la dirección de la cámara en
	# paralelo — así el disparo siempre converge con la mira, sin importar
	# la distancia entre PuntoDisparo y la cámara
	proyectil.direccion = calcular_direccion_disparo()

	# El daño del proyectil ahora depende del daño base + lo que suman los items
	proyectil.daño = int(daño_base + bono_daño)

func calcular_direccion_disparo() -> Vector3:
	var espacio_estado := get_world_3d().direct_space_state
	var origen := camara.global_position
	var destino := origen + (-camara.global_transform.basis.z) * 1000.0

	var consulta := PhysicsRayQueryParameters3D.create(origen, destino)
	consulta.exclude = [self]  # que no se choque consigo mismo (el jugador)
	var resultado := espacio_estado.intersect_ray(consulta)

	var punto_apuntado: Vector3 = resultado.position if resultado else destino

	return (punto_apuntado - punto_disparo.global_position).normalized()

func atacar_melee() -> void:
	if not puede_atacar_melee:
		return
	if escena_ataque_melee == null:
		push_warning("Falta asignar 'escena_ataque_melee' en el Inspector")
		return

	var ataque = escena_ataque_melee.instantiate()

	# Lo agregamos como hijo del Player (no de la escena principal), así se
	# mueve y rota automáticamente junto con el jugador mientras dura
	add_child(ataque)

	# Al ser hijo, la posición es LOCAL: -Z es "adelante" en Godot
	ataque.position = Vector3(0, altura_melee, -distancia_melee)
	ataque.daño = int(daño_base + bono_daño)

	puede_atacar_melee = false
	await get_tree().create_timer(cooldown_melee).timeout
	puede_atacar_melee = true

func _physics_process(delta: float) -> void:
	if not esta_vivo:
		return

	# --- GRAVEDAD ---
	if not is_on_floor():
		velocity.y -= gravedad * delta

	# --- SALTO ---
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = fuerza_salto

	# --- MOVIMIENTO ---
	# Leemos el input direccional (configurar en Input Map: mover_adelante,
	# mover_atras, mover_izquierda, mover_derecha)
	var input_dir := Vector2(
		Input.get_action_strength("mover_derecha") - Input.get_action_strength("mover_izquierda"),
		Input.get_action_strength("mover_atras") - Input.get_action_strength("mover_adelante")
	)

	# Convertimos el input 2D en una dirección 3D relativa a hacia dónde
	# mira el personaje (no la cámara global), para que W siempre sea "adelante"
	var direccion := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	var vel_actual := velocidad * multiplicador_correr if Input.is_action_pressed("correr") else velocidad

	if direccion.length() > 0.01:
		velocity.x = direccion.x * vel_actual
		velocity.z = direccion.z * vel_actual
	else:
		# Frenado suave en vez de parar en seco
		velocity.x = move_toward(velocity.x, 0, vel_actual)
		velocity.z = move_toward(velocity.z, 0, vel_actual)

	move_and_slide()
	actualizar_animacion()

# Llamado desde afuera (proyectiles enemigos, ataque de contacto, etc.)
func recibir_daño(cantidad: int) -> void:
	if not esta_vivo:
		return

	vida_actual = max(vida_actual - cantidad, 0)
	vida_cambio.emit(vida_actual, vida_maxima)

	if vida_actual <= 0:
		morir()

func morir() -> void:
	esta_vivo = false
	velocity = Vector3.ZERO
	murio.emit()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	print("El jugador murió. Game Over.")

# Llamado desde item.gd cuando el jugador toca un item
func subir_stat(tipo: String, cantidad: float) -> void:
	match tipo:
		"daño":
			bono_daño += cantidad
			print("¡Daño aumentado! Daño actual: ", daño_base + bono_daño)
		"velocidad":
			bono_velocidad += cantidad
			velocidad += cantidad
			print("¡Velocidad aumentada! Velocidad actual: ", velocidad, " | Corriendo: ", velocidad * multiplicador_correr)
		"vida":
			vida_maxima += int(cantidad)
			vida_actual += int(cantidad)
			vida_cambio.emit(vida_actual, vida_maxima)
			print("¡Vida máxima aumentada! Vida actual: ", vida_maxima)
		_:
			push_warning("Tipo de mejora desconocido: " + tipo)

func actualizar_animacion() -> void:
	if not esta_vivo or animation_player == null:
		return

	# Medimos qué tan rápido nos movemos en el plano horizontal (ignorando
	# el salto/caída en Y) para decidir si estamos quietos, caminando o corriendo
	var velocidad_horizontal := Vector2(velocity.x, velocity.z).length()

	var animacion_deseada: String
	if velocidad_horizontal < 0.5:
		animacion_deseada = "idle"
	elif Input.is_action_pressed("correr"):
		animacion_deseada = "run"
	else:
		animacion_deseada = "walk"

	# Traducimos el nombre corto al nombre completo con prefijo de biblioteca
	var nombre_real: String = mapa_animaciones.get(animacion_deseada, animacion_deseada)

	# Solo cambiamos de animación si es distinta a la que ya se está
	# reproduciendo, para no reiniciarla en cada frame sin necesidad
	if animation_player.current_animation != nombre_real:
		animation_player.play(nombre_real, duracion_transicion_animacion)
