extends Node3D

@export var pickup_sound : AudioStreamPlayer3D

func _on_area_3d_body_entered(body: Node3D) -> void:
	if not visible:
		return
	body.add_jump_use()
	visible = false
	pickup_sound.play()
	$RespawnTimer.start()

func _on_respawn_timer_timeout() -> void:
	visible = true
