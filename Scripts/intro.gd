extends PanelContainer

func _ready() -> void:
	Engine.time_scale = 0.0
	pass
	
func _input(event : InputEvent) -> void:
	if visible and event.is_action_pressed("jump"):
		self.visible = false
		Engine.time_scale = 1.0
