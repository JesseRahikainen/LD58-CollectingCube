extends Node3D

@export var velocity : Vector3 = Vector3.ZERO

func _physics_process(delta: float) -> void:
	rotation.x += velocity.x * delta
	rotation.y += velocity.y * delta
	rotation.z += velocity.z * delta
