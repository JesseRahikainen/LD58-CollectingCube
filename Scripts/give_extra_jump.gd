extends Node3D


func _on_area_3d_body_entered(body: Node3D) -> void:
	body.give_extra_jump()
	get_tree().queue_delete(self)
