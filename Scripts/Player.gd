class_name Player extends CharacterBody3D

@onready var player_mesh = $PlayerMesh
@onready var player_collision = $PlayerCollision

@onready var head = $Head
@onready var player_view = $Head/PlayerView

@export var BOB_FREQUENCY: float = 2.0
@export var BASE_FOV     : float = 90.0
@export var MOUSE_SENSITIVITY: float = 0.003
@onready var _standing_height: float = head.position.y
@onready var _crouch_height: float = _standing_height * 0.7
@onready var _collision_standing_size: float = player_collision.scale.y

const BOB_AMPLIFICATION: float  = 0.08
const TILT_LOWER_LIMIT : float  = deg_to_rad(-60)
const TILT_UPPER_LIMIT : float  = deg_to_rad(90)
const FOV_MULTIPLIER   : float  = 1.5
const FLOOR_VELOCITY_MULTIPLIER: float = 7.0
const AIR_VELOCITY_MULTIPLIER  : float = 3.0

const INPUTS: Dictionary = {
	MOVE_LEFT     = "left",
	MOVE_FORWARD  = "forward",
	MOVE_RIGHT    = "right",
	MOVE_BACKWARD = "backward",
	SPRINT        = "sprint",
	TIP_TOE       = "tiptoe",
	CROUCH        = "crouch",
	JUMP          = "jump",
	EXIT          = "exit"
}

const STATES: Dictionary = {
	IDLE    = { NAME = "PlayerIdleState", ACTION = null },
	WALK    = { NAME = "PlayerWalkState", ACTION = null },
	SPRINT  = { NAME = "PlayerSprintState", ACTION = INPUTS.SPRINT },
	TIP_TOE = { NAME = "PlayerTipToeState", ACTION = INPUTS.TIP_TOE },
	JUMP    = { NAME = "PlayerJumpState", ACTION = INPUTS.JUMP },
	DOUBLE_JUMP = { NAME = "PlayerDoubleJumpState", ACTION = INPUTS.JUMP },
	FALL    = { NAME = "PlayerFallState", ACTION = null },
	CROUCH = { NAME = "PlayerCrouchState", ACTION = INPUTS.CROUCH }
}

var _t_bob: float = 0.0
# Get the gravity from the project settings to be synced with RigidBody nodes.
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func update_input(speed: float, acceleration: float, deceleration: float) -> void:
	var _input_dir: Vector2 = Input.get_vector(INPUTS.MOVE_LEFT, INPUTS.MOVE_RIGHT, INPUTS.MOVE_FORWARD, INPUTS.MOVE_BACKWARD)
	var _direction: Vector3 = (head.transform.basis * Vector3(_input_dir.x, 0, _input_dir.y)).normalized()
	
	if _direction:
		velocity.x = lerp(velocity.x, _direction.x * speed, acceleration)
		velocity.z = lerp(velocity.z, _direction.z * speed, acceleration)
	else:
		var current_velocity = Vector3(velocity.x, velocity.y, velocity.z)
		var temp_vector = move_toward(Vector3(velocity.x, velocity.y, velocity.z).length(), 0, deceleration)
		velocity.x = current_velocity.normalized().x * temp_vector
		velocity.z = current_velocity.normalized().z * temp_vector
		
func is_in_air() -> bool:
	return !is_on_floor()

func update_headbob(delta: float) -> void:
	if is_in_air():
		# We don't apply headbob while jumping/falling so
		# take this opportunity to reset the "bob time" counter.
		# otherwise this would keep incrementing off into infinity.
		# Be a little more memory efficient.
		_t_bob = lerp(_t_bob, 0.0, delta * 0.5)
	else:
		_t_bob += delta * velocity.length() * float(is_on_floor())
		player_view.transform.origin = _headbob(_t_bob)

func update_fov(speed: float, delta: float) -> void:
	var target_fov = BASE_FOV + FOV_MULTIPLIER * clamp(velocity.length(), 0.5, speed * 2)
	player_view.fov = lerp(player_view.fov, target_fov, delta * 9.0)

func update_gravity(delta: float) -> void:
	velocity.y -= _gravity * delta

func handle_crouch(crouched: bool):
	# Smoke test -- this kinda works for setting camera to a lower position.
	# would like to use code to control crouching rather than an animation player, I think...
	head.position.y = _crouch_height if crouched else _standing_height
	player_collision.scale.y = _collision_standing_size * 0.7 if crouched else _collision_standing_size

func update_velocity() -> void:
	move_and_slide()

# PRIVATE

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
	if event.is_action_pressed(INPUTS.EXIT):
		get_tree().quit()

func _is_moving_mouse_in_captured_window(event: InputEvent) -> bool:
	return event is InputEventMouseMotion && Input.mouse_mode == Input.MOUSE_MODE_CAPTURED

func _physics_process(_delta: float) -> void:
	pass
	# Get the input direction and handle the movement/deceleration.
	# TODO: get rid of this commented code.  Keeping it here for now because it's a bit different
	# than what's in the update_input method below.  need to test to see if there's any
	# measurable difference between the implementations.
	#var _input_dir: Vector2 = Input.get_vector("left", "right", "forward", "backward")
	#var _direction: Vector3 = (head.transform.basis * Vector3(_input_dir.x, 0, _input_dir.y)).normalized()

func _headbob(time: float) -> Vector3:
	var pos: Vector3 = Vector3.ZERO
	pos.y = sin(time * BOB_FREQUENCY) * BOB_AMPLIFICATION
	pos.x = cos(time * BOB_FREQUENCY / 2) * BOB_AMPLIFICATION
	return pos


