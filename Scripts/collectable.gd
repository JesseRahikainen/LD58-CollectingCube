class_name Collectable
extends Node3D

@export var collect_sound : AudioStreamPlayer3D

static var max_collectables : int = 0
static var gotten_collectables : int = 0

static func reset_collectables_count() -> void:
	max_collectables = 0
	gotten_collectables = 0
	
func _ready() -> void:
	if visible:
		max_collectables += 1
		MessageBus.on_collectable_collected.emit()

func _on_area_3d_body_entered(_body: Node3D) -> void:
	if not visible:
		return
	gotten_collectables += 1
	MessageBus.on_collectable_collected.emit()
	collect_sound.play()
	visible = false
	#get_tree().queue_delete(self)
