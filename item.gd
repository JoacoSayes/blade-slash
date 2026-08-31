extends Area3D

# Elegí el tipo de mejora que da este item en particular desde el Inspector
@export_enum("daño", "velocidad", "vida") var tipo_mejora: String = "daño"
@export var cantidad: float = 5.0

func _on_body_entered(body: Node3D) -> void:
	if body.has_method("subir_stat"):
		body.subir_stat(tipo_mejora, cantidad)
		queue_free()
