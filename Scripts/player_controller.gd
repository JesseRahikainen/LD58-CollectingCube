class_name PlayerController
extends CharacterBody3D

@export var speed : float = 5.0
@export var post_dash_speed : float = 40.0
@export var dash_speed : Curve
@export var jump_velocity : float = 4.5
@export var camera_root : Node3D
@export var yaw_turn_speed : float = 0.05
@export var break_accel : float = 80.0
@export var shader_velocity_change : float = 0.5
@export var gravity_scale : float = 1.0
@export_flags_3d_physics var wall_jump_collision_layers
@export var wall_jump_velocity : float = 3.0
@export var wall_jump_horiz_velocity : float = 15.0
@export var wall_jump_input_scale : Curve
@export var max_air_jumps : int = 1

@export var jump_sound : AudioStreamPlayer3D
@export var death_sound : AudioStreamPlayer3D
@export var extra_jump_sound : AudioStreamPlayer3D
@export var dash_sound : AudioStreamPlayer3D

enum PlayerState { NORMAL, DASHING, WALL_JUMPING, BOOSTED }
var state : PlayerState = PlayerState.NORMAL

var dash_direction : Vector3
var time_in_dash : float = -1.0
var use_post_dash_speed : bool = false

var num_jumps_left : int = 0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var shader : ShaderMaterial
var shader_velocity : Vector3 = Vector3.ZERO

var time_in_wall_jump : float = -1.0
var wall_jump_dir : Vector3 = Vector3.ZERO

var global_input_move_direction : Vector3 = Vector3.ZERO

var last_valid_position : Vector3 = Vector3.ZERO

var boost_vel : Vector3 = Vector3.ZERO
var time_boosted : float = 0.0

var num_deaths : int = 0
var time_played : float = 0.0

func _allow_input() -> bool:
	return Engine.time_scale > 0.0

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	shader = $player_box/Cube.get_active_material(0) as ShaderMaterial
	MessageBus.max_jumps_changed.emit(max_air_jumps)

func _check_jump(_delta: float) -> void:
	if not _allow_input():
		return
	
	if is_on_floor():
		num_jumps_left = max_air_jumps
		MessageBus.num_jumps_changed.emit(num_jumps_left)
	
	var can_jump: bool = is_on_floor() or num_jumps_left > 0
	if Input.is_action_just_pressed("jump") and can_jump:
		# start the jump
		if not is_on_floor():
			num_jumps_left -= 1
			MessageBus.num_jumps_changed.emit(num_jumps_left)
		velocity.y = jump_velocity
		jump_sound.play()
	elif not is_on_floor() and not Input.is_action_pressed("jump") and velocity.y > 0.0:
		# stop movement if we're moving up and let go of jump, will cause issues with any sort of vertical boost
		#  will want to split the jump velocity out
		if time_boosted > 1.0:
			velocity.y = 0.0
		
func _process_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta * gravity_scale

# returns the ray cast result so we can get stuff from it
func _touching_wall() -> Dictionary:
	var space = get_world_3d().direct_space_state
	if velocity.length_squared() > 0.1:
		var query = PhysicsRayQueryParameters3D.create(position, position + velocity.normalized() * 2.0, wall_jump_collision_layers )
		var result = space.intersect_ray(query)
		if result and abs(Vector3.UP.dot(result.normal)) < 0.7: # only jump if the angle is less than 45 deg
			return result
	return { }
	
func _moving_into_wall() -> Dictionary:
	var space = get_world_3d().direct_space_state
	var input_dir : Vector2 = Input.get_vector("left", "right", "forward", "backward")
	if input_dir.length_squared() > 0.1:
		var global_input_dir : Vector3 = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		var query = PhysicsRayQueryParameters3D.create(position, position + global_input_dir * 2.0, wall_jump_collision_layers )
		var result = space.intersect_ray(query)
		if result and abs(Vector3.UP.dot(result.normal)) < 0.7: # only jump if the angle is less than 45 deg
			return result
	return { }

func _check_wall_jump(delta: float) -> bool:
	if not is_on_floor():
		# ray cast to see if we're contacting something
		var result = _moving_into_wall()
		if result:
			#print_debug("can wall jump")
			if _allow_input() and Input.is_action_just_pressed("jump"):
				# propel away from the wall and upwards
				jump_sound.play()
				_start_wall_jump(delta, result.normal)
				return true
	return false
	
func _start_wall_jump(delta: float, direction: Vector3) -> void:
	# we want an arc away from the wall and the player gets more control as the
	#  the state nears it's end, so we'll do the same basic horizontal input
	#  allow dash as well
	state = PlayerState.WALL_JUMPING
	wall_jump_dir = direction
	velocity.y = wall_jump_velocity
	time_in_wall_jump = 0.0
	use_post_dash_speed = false
	_physics_process_wall_jump(delta)

func _physics_process_wall_jump(delta: float) -> void:
	_process_gravity(delta)
	
	# let them dash after a bit
	if time_in_wall_jump > wall_jump_input_scale.max_domain / 2:
		if _allow_input() and Input.is_action_just_pressed("dash"):
			_start_dash(delta, global_input_move_direction)
			return
	
	var inputVel = _get_movement(delta)
	var yVel = velocity.y # so we don't cancel out jumping and gravity
	velocity = lerp(wall_jump_dir * wall_jump_horiz_velocity, inputVel, wall_jump_input_scale.sample(time_in_wall_jump))
	velocity.y = yVel
	time_in_wall_jump += delta
	if time_in_wall_jump >= wall_jump_input_scale.max_domain:
		state = PlayerState.NORMAL
	move_and_slide()

func _start_dash(delta: float, direction: Vector3) -> void:
	state = PlayerState.DASHING
	# first see which direction we're currently moving and lock that in for the dash
	#  if we're still then just use forward
	dash_direction = direction
	if dash_direction.length_squared() <= 0.0:
		dash_direction = -transform.basis.z
		
	time_in_dash = 0.0
	use_post_dash_speed = true
	
	dash_sound.play()
	
	_physics_process_dashing(delta)

func _get_movement(delta: float) -> Vector3:
	var curr_speed : float = speed
	var newVel : Vector3 = Vector3.ZERO
	if global_input_move_direction:
		if use_post_dash_speed:
			curr_speed = post_dash_speed
		newVel.x = global_input_move_direction.x * curr_speed
		newVel.z = global_input_move_direction.z * curr_speed
	else:
		use_post_dash_speed = false
		newVel.x = move_toward(velocity.x, 0, break_accel * delta)
		newVel.z = move_toward(velocity.z, 0, break_accel * delta)
	newVel.y = velocity.y
	return newVel

func _physics_process_normal(delta: float) -> void:
	# gravity
	var wasGrounded : bool = true
	if not is_on_floor():
		wasGrounded = false

	_process_gravity(delta)
	if _check_wall_jump(delta):
		return
	_check_jump(delta)
	
	# start dashing as soon as we get the input
	if _allow_input() and Input.is_action_just_pressed("dash"):
		_start_dash(delta, global_input_move_direction)
		return
	
	velocity = _get_movement(delta)

	# if moving turn the character head in the same way the camera is looking
	if global_input_move_direction:
		var desiredYaw : float = camera_root.global_rotation.y
		var yawDiff : float = angle_difference(global_rotation.y, desiredYaw)
		var yawMaxVel : float = yaw_turn_speed * delta
		var yawVel = clamp(abs(yawDiff), 0.0, yawMaxVel) * sign(yawDiff)
		global_rotation.y += yawVel

	move_and_slide()
	
	if not wasGrounded and is_on_floor():
		# landed
		shader_velocity.y = 0.0
	
func _physics_process_dashing(delta: float) -> void:
	
	_process_gravity(delta)
	_check_jump(delta)
	
	velocity.x = 0.0
	velocity.z = 0.0
	velocity += dash_direction * dash_speed.sample(time_in_dash)
	
	time_in_dash += delta
	
	# bounce off of walls
	var wall_result = _touching_wall()
	if wall_result:
		dash_direction = dash_direction.bounce(wall_result.normal)
	
	# time out of state
	if time_in_dash > dash_speed.max_domain:
		use_post_dash_speed = is_on_floor()
		state = PlayerState.NORMAL
		
	move_and_slide()

func died() -> void:
	global_position = last_valid_position
	velocity = Vector3.ZERO
	state = PlayerState.NORMAL
	death_sound.play()
	num_deaths += 1

func _physics_process(delta : float) -> void:	
	if is_on_floor():
		last_valid_position = global_position
	
	if global_position.y < -64.0:
		died()
	
	var input_dir : Vector2 = Input.get_vector("left", "right", "forward", "backward")
	global_input_move_direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	match state:
		PlayerState.NORMAL:
			_physics_process_normal(delta)
		PlayerState.DASHING:
			_physics_process_dashing(delta)
		PlayerState.WALL_JUMPING:
			_physics_process_wall_jump(delta)
		PlayerState.BOOSTED:
			_physics_process_boosted(delta)
		_:
			print_debug("Invalid player state, cannot process physics")
	
	shader_velocity = lerp(shader_velocity, velocity, shader_velocity_change * delta) # smooth out the graphics
	# need to convert the velocity into model space
	shader.set_shader_parameter("velocity", basis.inverse()*shader_velocity)

func add_jump_use() -> void:
	num_jumps_left = min( num_jumps_left + 1, max_air_jumps )
	MessageBus.num_jumps_changed.emit(num_jumps_left)
	
func give_extra_jump() -> void:
	max_air_jumps += 1
	num_jumps_left += 1
	extra_jump_sound.play()
	MessageBus.max_jumps_changed.emit(max_air_jumps)
	MessageBus.num_jumps_changed.emit(num_jumps_left)

func _physics_process_boosted(delta: float) -> void:
	velocity = boost_vel
	time_boosted += delta
	
	if time_boosted >= 1.0:
		state = PlayerState.NORMAL
		
	move_and_slide()

func boost(vel: Vector3) -> void:
	# kind of like a dash, only it ignores gravity and any input for a bit
	boost_vel = vel
	time_boosted = 0.0
	state = PlayerState.BOOSTED

func _process(delta: float) -> void:
	time_played += delta
