extends CharacterBody3D

@onready var head = $Head
@onready var player_view = $Head/PlayerView

@export var WALK_SPEED   : float = 5.0
@export var SPRINT_SPEED : float = 7.0
@export var TIP_TOE_SPEED: float = 2.0
@export var JUMP_VELOCITY: float = 4.5
@export var BOB_FREQUENCY: float = 2.0
@export var BASE_FOV     : float = 90.0
@export var MOUSE_SENSITIVITY: float = 0.003

const BOB_AMPLIFICATION: float  = 0.08
const TILT_LOWER_LIMIT : float  = deg_to_rad(-60)
const TILT_UPPER_LIMIT : float  = deg_to_rad(90)
const FOV_MULTIPLIER   : float  = 1.5
const FLOOR_VELOCITY_MULTIPLIER: float = 7.0
const AIR_VELOCITY_MULTIPLIER  : float = 3.0

var _t_bob: float = 0.0
var _speed: float = WALK_SPEED
var _is_double_jumping: bool = false
# Get the gravity from the project settings to be synced with RigidBody nodes.
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	if _is_moving_mouse_in_captured_window(event):
		head.rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		player_view.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		player_view.rotation.x = clamp(player_view.rotation.x, TILT_LOWER_LIMIT, TILT_UPPER_LIMIT)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("exit"):
		get_tree().quit()

func _is_moving_mouse_in_captured_window(event: InputEvent) -> bool:
	return event is InputEventMouseMotion && Input.mouse_mode == Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if _is_in_air():
		# We don't apply headbob while jumping/falling so
		# take this opportunity to reset the "bob time" counter.
		# otherwise this would keep incrementing off into infinity.
		# Be a little more memory efficient.
		_t_bob = lerp(_t_bob, 0.0, delta * 0.5)
		velocity.y -= _gravity * delta
	else:
		_is_double_jumping = false

	# Handle jump.
	# TODO: This won't let you double jump if you have just fallen off a ledge;
	# you'll only be able to jump once
	# Fix that.
	if Input.is_action_just_pressed("jump") && is_on_floor():
		velocity.y = JUMP_VELOCITY
	elif Input.is_action_just_pressed("jump") && !_is_double_jumping:
		if velocity.y <= JUMP_VELOCITY:
			_is_double_jumping = true
			# TODO: constantize these values of 1.5 and 5.  Not really sure how to calculate proper
			# values for these inputs, just went off of in-game "feel" for the current values.
			# TODO: Double jumping feels a bit floaty right now, especially when sprinting.
			# Might need to back off these values a bit or consider whether double jump should be
			# disabled when sprinting?
			velocity.y = clamp(JUMP_VELOCITY * 1.5, JUMP_VELOCITY, 5)

	# Get the input direction and handle the movement/deceleration.
	var _input_dir: Vector2 = Input.get_vector("left", "right", "forward", "backward")
	var _direction: Vector3 = (head.transform.basis * Vector3(_input_dir.x, 0, _input_dir.y)).normalized()

	# I think this method of movement control is kinda broken.  Think there needs to be a separation of
	# concerns between input (new/existing) and inertia.
	# E.g. can't easily continue moving in a vector based on airspeed AND prevent user input from
	# initiating sprint, for example, mid-air.
	_update_velocity(_direction, delta)

	# Head bob
	_t_bob += delta * velocity.length() * float(is_on_floor())

	player_view.transform.origin = _headbob(_t_bob)
	player_view.fov = lerp(player_view.fov, _calculate_fov(), delta * 8.0)

	move_and_slide()

func _update_velocity(direction: Vector3, delta: float) -> void:

	_speed = _set_movement_speed()

	if direction:
		velocity.x = direction.x * _speed
		velocity.z = direction.z * _speed
	else:
		var _multiplier: float = AIR_VELOCITY_MULTIPLIER if _is_in_air() else FLOOR_VELOCITY_MULTIPLIER
		var _new_vector: Vector3 = Vector3.ZERO
		_new_vector.x = lerp(velocity.x, direction.x * _speed, delta * _multiplier)
		_new_vector.y = velocity.y
		_new_vector.z = lerp(velocity.z, direction.z * _speed, delta * _multiplier)
		velocity = _new_vector

func _set_movement_speed() -> float:
	# Avoid letting the player change between walking and sprinting while in the air.
	if _is_in_air():
		return _speed

	if Input.is_action_pressed("sprint"):
		return SPRINT_SPEED

	if Input.is_action_pressed("tiptoe"):
		return TIP_TOE_SPEED

	return	WALK_SPEED

func _is_in_air() -> bool:
	return !is_on_floor()

func _calculate_fov() -> float:
	return BASE_FOV + FOV_MULTIPLIER * clamp(velocity.length(), 0.5, _speed * 2)

func _headbob(time: float) -> Vector3:
	var pos: Vector3 = Vector3.ZERO
	pos.y = sin(time * BOB_FREQUENCY) * BOB_AMPLIFICATION
	pos.x = cos(time * BOB_FREQUENCY / 2) * BOB_AMPLIFICATION
	return pos
