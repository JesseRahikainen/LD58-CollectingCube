extends Node

@export var max_label : Label
@export var curr_label : Label

func _ready() -> void:
	MessageBus.on_collectable_collected.connect(Callable(self, "_update_collected"))
	_update_collected()
	
func _update_collected() -> void:
	max_label.text = str(Collectable.max_collectables)
	curr_label.text = str(Collectable.gotten_collectables)
