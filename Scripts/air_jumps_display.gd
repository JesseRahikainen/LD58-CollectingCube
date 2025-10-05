extends HBoxContainer

@export var indicators : Array[Control]

func _ready() -> void:
	MessageBus.max_jumps_changed.connect(Callable(self, "_max_jumps_changed"))
	MessageBus.num_jumps_changed.connect(Callable(self, "_num_jumps_changed"))
	
func _max_jumps_changed(jumps: int) -> void:
	for i in len(indicators):
		indicators[i].visible = i < jumps

func _num_jumps_changed(jumps: int) -> void:
	for i in len(indicators):
		var jumpIndicator = indicators[i] as JumpIndicator
		jumpIndicator.set_indicator_shown(i < jumps)
