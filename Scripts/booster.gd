extends Node3D

@export var sound : AudioStreamPlayer3D

# make the player dash in the direction of the boost
const BOOST_VEL_Y_SCALE : float = 10.0 # strength of boost is based on y scale

func _on_area_3d_body_entered(body: Node3D) -> void:
	var boostVel : Vector3 = transform.basis * Vector3.UP * BOOST_VEL_Y_SCALE
	body.boost(boostVel)
	sound.play()
