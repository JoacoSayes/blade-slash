extends Node3D

@onready var particulas: GPUParticles3D = $GPUParticles3D
@onready var sonido: AudioStreamPlayer3D = $AudioStreamPlayer3D

func _ready() -> void:
	particulas.emitting = true

	if sonido.stream != null:
		sonido.play()

	# Esperamos lo que dure más: la vida de las partículas o el sonido,
	# para no cortar ninguno de los dos a la mitad
	var espera := particulas.lifetime
	if sonido.stream != null:
		espera = max(espera, sonido.stream.get_length())

	await get_tree().create_timer(espera).timeout
	queue_free()
