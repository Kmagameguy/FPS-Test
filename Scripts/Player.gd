class_name Player extends CharacterBody3D

@onready var head = $Head
@onready var player_view = $Head/PlayerView
@onready var collision: CollisionShape3D = $PlayerCollision
@onready var player_mesh: MeshInstance3D = $PlayerMesh
@onready var _floor_offset: float = collision.transform.origin.y - STAND_HEIGHT * 0.5
@onready var _standing_head_y: float = head.transform.origin.y
@export var BOB_FREQUENCY: float = 2.0
@export var BASE_FOV     : float = 90.0
@export var MOUSE_SENSITIVITY: float = 0.003
@export var STAND_HEIGHT: float = 2.0
@export var CROUCH_HEIGHT: float = 1.0
@export var CAPSULE_RADIUS: float = 0.5
@export var FALL_VELOCITY_THRESHOLD: float = -3.0
@export var CROUCH_TRANSITION_SPEED: float = 0.05 # represents height-units-per-second

const BOB_AMPLIFICATION: float  = 0.08
const TILT_LOWER_LIMIT : float  = deg_to_rad(-60)
const TILT_UPPER_LIMIT : float  = deg_to_rad(90)
const FOV_MULTIPLIER   : float  = 1.5
const FLOOR_VELOCITY_MULTIPLIER: float = 7.0
const AIR_VELOCITY_MULTIPLIER  : float = 3.0

const STATES: Dictionary = {
	IDLE    = { NAME = "PlayerIdleState", ACTION = null },
	WALK    = { NAME = "PlayerWalkState", ACTION = null },
	SPRINT  = { NAME = "PlayerSprintState", ACTION = "sprint" },
	TIP_TOE = { NAME = "PlayerTipToeState", ACTION = "tiptoe"},
	JUMP    = { NAME = "PlayerJumpState", ACTION = "jump" },
	DOUBLE_JUMP = { NAME = "PlayerDoubleJumpState", ACTION = "jump" },
	FALL    = { NAME = "PlayerFallState", ACTION = null },
	CROUCH  = { NAME = "PlayerCrouchState", ACTION = "crouch" }
}

var _t_bob: float = 0.0
# Get the gravity from the project settings to be synced with RigidBody nodes.
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

var _stand_check_shape := CapsuleShape3D.new()
var _target_stance_height: float
var _mesh_stance_height: float

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_stand_check_shape.radius = CAPSULE_RADIUS
	_stand_check_shape.height = STAND_HEIGHT
	_target_stance_height = STAND_HEIGHT
	_mesh_stance_height = STAND_HEIGHT

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

func _process(_delta: float) -> void:
	if _mesh_stance_height == _target_stance_height:
		return

	_mesh_stance_height = move_toward(_mesh_stance_height, _target_stance_height, CROUCH_TRANSITION_SPEED)
	(player_mesh.mesh as CapsuleMesh).height = _mesh_stance_height
	player_mesh.transform.origin.y = _floor_offset + _mesh_stance_height * 0.5
	head.transform.origin.y = _standing_head_y - (STAND_HEIGHT - _mesh_stance_height)

func _physics_process(_delta: float) -> void:
	var current_height: float = collision.shape.height
	if current_height == _target_stance_height:
		return
	
	var new_height := move_toward(current_height, _target_stance_height, CROUCH_TRANSITION_SPEED)
	(collision.shape as CapsuleShape3D).height = new_height
	collision.transform.origin.y = _floor_offset + new_height * 0.5

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

func set_stance_height(height: float) -> void:
	_target_stance_height = height

func can_stand_up() -> bool:
	if collision.shape.height >= STAND_HEIGHT:
		return true

	var space_state := get_world_3d().direct_space_state
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = _stand_check_shape
	query.transform = global_transform
	query.transform.origin.y = global_position.y + _floor_offset + STAND_HEIGHT * 0.5
	query.exclude = [get_rid()]
	query.collision_mask = collision_mask

	return space_state.intersect_shape(query, 1).is_empty()

func _headbob(time: float) -> Vector3:
	var pos: Vector3 = Vector3.ZERO
	pos.y = sin(time * BOB_FREQUENCY) * BOB_AMPLIFICATION
	pos.x = cos(time * BOB_FREQUENCY / 2) * BOB_AMPLIFICATION
	return pos

func update_gravity(delta: float) -> void:
	velocity.y -= _gravity * delta

func update_input(speed: float, acceleration: float, deceleration: float) -> void:
	var _input_dir: Vector2 = Input.get_vector("left", "right", "forward", "backward")
	var _direction: Vector3 = (head.transform.basis * Vector3(_input_dir.x, 0, _input_dir.y)).normalized()

	if _direction:
		velocity.x = lerp(velocity.x, _direction.x * speed, acceleration)
		velocity.z = lerp(velocity.z, _direction.z * speed, acceleration)
	else:
		var horizontal_velocity := Vector3(velocity.x, 0, velocity.z)
		var new_speed := move_toward(horizontal_velocity.length(), 0, deceleration)
		var new_horizontal := horizontal_velocity.normalized() * new_speed

		velocity.x = new_horizontal.x
		velocity.z = new_horizontal.z

func update_velocity() -> void:
	move_and_slide()
