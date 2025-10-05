extends PanelContainer

@export var death_count : Label
@export var time_played : Label
@export var player : PlayerController

func _notification(evt: int) -> void:
	if evt == NOTIFICATION_VISIBILITY_CHANGED:
		if visible:
			death_count.text = "Num Deaths: " + str( player.num_deaths )
			
			var time = player.time_played
			var ms: int = floori( time * 100 ) % 100
			var sec: int = floori( time ) % 60
			var min: int = floori( time / 60.0 )
			time_played.text = "Time: " + "%02d:%02d.%03d" % [min, sec, ms]
