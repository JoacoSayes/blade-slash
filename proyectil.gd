extends Area3D

@export var velocidad: float = 25.0
@export var daño: int = 10
@export var tiempo_vida: float = 3.0

# Arrastrá acá la escena EfectoImpacto.tscn
@export var escena_efecto_impacto: PackedScene

var direccion: Vector3 = Vector3.FORWARD

func _ready() -> void:
	# Autodestruye el proyectil después de un tiempo, por si no pega contra nada
	await get_tree().create_timer(tiempo_vida).timeout
	if is_instance_valid(self):
		queue_free()

func _physics_process(delta: float) -> void:
	global_position += direccion * velocidad * delta

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("enemigos") and body.has_method("recibir_daño"):
		body.recibir_daño(daño)

	spawnear_efecto_impacto()
	queue_free()

func spawnear_efecto_impacto() -> void:
	if escena_efecto_impacto == null:
		return
	var efecto = escena_efecto_impacto.instantiate()
	get_tree().current_scene.add_child(efecto)
	efecto.global_position = global_position
