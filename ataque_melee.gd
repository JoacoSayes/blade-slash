extends Area3D

@export var daño: int = 15
@export var duracion_visual: float = 0.15

@onready var mesh: MeshInstance3D = $MeshInstance3D

var cuerpos_golpeados: Array = []

func _ready() -> void:
	# Escuchamos la señal en vez de depender de un solo chequeo puntual:
	# así detectamos el contacto apenas ocurra, sin importar el timing exacto
	body_entered.connect(_on_body_entered)

	# Esperamos un par de frames de física para darle tiempo al motor a
	# terminar de registrar la forma nueva y procesar las colisiones
	await get_tree().physics_frame
	await get_tree().physics_frame

	# Sumamos también lo que haya quedado overlapeado directamente, por las dudas
	for cuerpo in get_overlapping_bodies():
		if cuerpo not in cuerpos_golpeados:
			cuerpos_golpeados.append(cuerpo)

	print("Ataque melee golpeó %d cuerpo(s): %s" % [cuerpos_golpeados.size(), cuerpos_golpeados])
	aplicar_daño()
	animar_y_desaparecer()

func _on_body_entered(cuerpo: Node3D) -> void:
	if cuerpo not in cuerpos_golpeados:
		cuerpos_golpeados.append(cuerpo)

func aplicar_daño() -> void:
	for cuerpo in cuerpos_golpeados:
		if cuerpo.is_in_group("enemigos") and cuerpo.has_method("recibir_daño"):
			cuerpo.recibir_daño(daño)

func animar_y_desaparecer() -> void:
	var tween := create_tween()
	tween.tween_property(mesh, "scale", Vector3.ZERO, duracion_visual)
	await tween.finished
	queue_free()
