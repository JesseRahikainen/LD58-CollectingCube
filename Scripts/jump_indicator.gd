class_name JumpIndicator
extends MarginContainer

@export var indictor_image : Control

func set_indicator_shown(shown: bool) -> void:
	indictor_image.visible = shown
