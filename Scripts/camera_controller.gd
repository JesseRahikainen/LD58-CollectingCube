extends Node3D

@export var horizontal_look_speed : float = 0.005
@export var vertical_look_speed : float = 0.005
@export var invert_vertical_look : bool = false
@export var vertical_look_min_angle_deg : float = -75.0
@export var vertical_look_max_angle_deg : float = -5.0
@export var position_follow_object : Node3D
@export var controller_horizontal_look_speed : float = 0.005
@export var controller_vertical_look_speed : float = 0.005

var yaw : float = 0.0
var pitch : float = 0.0
var look_accumulate_x : float = 0.0
var look_accumulate_y : float = 0.0

func _physics_process(_delta : float) -> void:
	if Engine.time_scale == 0.0:
		return
		
	# we want to follow the object without inheriting it's scale or rotation
	global_position = position_follow_object.global_position
	
	var input_dir : Vector2 = Input.get_vector("camera_left", "camera_right", "camera_up", "camera_down")
	
	# apply mouse look
	basis = Basis()
	yaw += -look_accumulate_x * horizontal_look_speed
	yaw -= input_dir.x * controller_horizontal_look_speed
	pitch = clamp(
		pitch - (look_accumulate_y * vertical_look_speed) - (input_dir.y * controller_vertical_look_speed),
		deg_to_rad(vertical_look_min_angle_deg),
		deg_to_rad(vertical_look_max_angle_deg))
	rotation = Vector3(pitch, yaw, 0)
	
	look_accumulate_x = 0.0
	look_accumulate_y = 0.0

func _input(event : InputEvent) -> void:
	if Engine.time_scale == 0.0:
		return
	# mouse look
	if event is InputEventMouseMotion:
		look_accumulate_x += event.relative.x
		look_accumulate_y += event.relative.y
