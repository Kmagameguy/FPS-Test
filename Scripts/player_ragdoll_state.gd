class_name PlayerRagdollState extends PlayerMovementState

@export var FACEPLANT_ANGLE:  float = deg_to_rad(85.0)
@export var FACEPLANT_SPEED:  float = 10.0
@export var STAND_UP_SPEED:   float = 8.0
@export var STAND_UP_STANCE_SPEED: float = 30.0 # height units/sec; keep it fast enough to finish before the rotation does
@export var FRICTION:         float = 10.0
@export var MOMENTUM_THRESHOLD: float = 0.5
@export var LANDING_RECOVERY_DELAY: float = 0.4

var _axis: Vector3 = Vector3.RIGHT
var _target_angle: float = 0.0
var _angle: float = 0.0
var _standing_up: bool = false
var _grounded_time: float = 0.0

func enter(_previous_state: PlayerState) -> void:
	_grounded_time = 0.0
	var horizontal_velocity := Vector3(PLAYER.velocity.x, 0.0, PLAYER.velocity.z)

	if horizontal_velocity.length() > MOMENTUM_THRESHOLD:
		var fall_direction := horizontal_velocity.normalized()
		_axis = Vector3.UP.cross(fall_direction.normalized())
		_target_angle = FACEPLANT_ANGLE
	else:
		_axis = PLAYER.head.global_transform.basis.x.normalized()
		_target_angle = -FACEPLANT_ANGLE

	_angle = 0.0
	_standing_up = false

func exit() -> void:
	PLAYER.basis = Basis.IDENTITY

func physics_update(delta: float) -> void:
	if _standing_up:
		_angle = move_toward(_angle, 0.0, STAND_UP_SPEED * delta)
	else:
		_angle = move_toward(_angle, _target_angle, FACEPLANT_SPEED * delta)

	PLAYER.basis = Basis(Quaternion(_axis, _angle))

	PLAYER.update_gravity(delta)
	PLAYER.velocity = PLAYER.velocity.move_toward(
		Vector3(0.0, PLAYER.velocity.y, 0.0), FRICTION * delta)
	PLAYER.update_velocity()

	if not _standing_up:
		if Input.is_action_pressed(PLAYER.STATES.RAGDOLL.ACTION):
			_grounded_time = 0.0
			return

		if PLAYER.is_in_air():
			_grounded_time = 0.0
			return

		_grounded_time += delta

		if _grounded_time < LANDING_RECOVERY_DELAY:
			return

		_standing_up = true

	# TODO: This is shitty but I couldn't figure out a better way to avoid
	# "Popping" up to standing height before transitioning to crouch height
	# without also causing the capsule to shrink/grow if crouch is pressed/released
	# while holding the ragdoll button. ugh. Probably need to rethink how
	# player height is managed (possibly as a separate state-like machine)
	var want_crouch := Input.is_action_pressed(PLAYER.STATES.CROUCH.ACTION)
	PLAYER.set_stance_height(
		PLAYER.CROUCH_HEIGHT if want_crouch else PLAYER.STAND_HEIGHT,
		STAND_UP_STANCE_SPEED)

	if _angle == 0.0:
		transition.emit(_stand_up_state())

func _stand_up_state() -> String:
	if Input.is_action_pressed(PLAYER.STATES.CROUCH.ACTION):
		return PLAYER.STATES.CROUCH.NAME
	return PLAYER.STATES.IDLE.NAME
