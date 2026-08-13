class_name PlayerSlideState extends PlayerMovementState

@export var SPEED          : float = 7.0
@export var FRICTION       : float = 4.0
@export var MIN_SLIDE_SPEED: float = 1.5

var _slide_velocity: Vector3 = Vector3.ZERO

func enter(_previous_state: PlayerState) -> void:
	PLAYER.set_stance_height(PLAYER.CROUCH_HEIGHT)
	_slide_velocity = Vector3(PLAYER.velocity.x, 0, PLAYER.velocity.z)

func update(delta: float) -> void:
	PLAYER.update_fov(SPEED, delta)

func physics_update(delta: float) -> void:
	PLAYER.update_gravity(delta)

	_slide_velocity = _slide_velocity.move_toward(Vector3.ZERO, FRICTION * delta)
	PLAYER.velocity.x = _slide_velocity.x
	PLAYER.velocity.z = _slide_velocity.z
	PLAYER.update_velocity()

	if _slide_velocity.length() <= MIN_SLIDE_SPEED && PLAYER.is_on_floor():
		if Input.is_action_pressed(PLAYER.STATES.CROUCH.ACTION) || !PLAYER.can_stand_up():
			transition.emit(PLAYER.STATES.CROUCH.NAME)
		else:
			transition.emit(PLAYER.STATES.IDLE.NAME)

	if PLAYER.velocity.y < PLAYER.FALL_VELOCITY_THRESHOLD && PLAYER.is_in_air():
		transition.emit(PLAYER.STATES.FALL.NAME)
