extends Node3D

@export var spawn_point : Node3D
@export var player : Node3D

func _ready():
	_respawn()
	MessageBus.on_collectable_collected.connect(Callable(self, "_target_collected"))

func _target_collected():
	if Collectable.gotten_collectables >= Collectable.max_collectables:
		$Congrats.visible = true
		Engine.time_scale = 0.0
		pass

func _input(event : InputEvent) -> void:
	if event.is_action_pressed("exit"):
		if $Congrats.visible:
			get_tree().quit()
		elif not $Intro.visible:
			if $PauseMenu.visible:
				Engine.time_scale = 1.0
				$PauseMenu.visible = false
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			else:
				Engine.time_scale = 0.0
				$PauseMenu.visible = true
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	#if event.is_action_pressed("respawn"):
	#	_respawn()

func _respawn() -> void:
	player.position = spawn_point.position

func _on_quit_pressed() -> void:
	get_tree().quit()
