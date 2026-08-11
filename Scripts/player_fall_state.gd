class_name PlayerFallState extends PlayerMovementState

@export var SPEED: float = 6.0
@export var ACCELERATION: float = 0.1
@export var DECELERATION: float = 0.25

var _previous_state: PlayerState

func enter(previous_state: PlayerState) -> void:
	_previous_state = previous_state

func update(delta: float) -> void:
	PLAYER.update_fov(SPEED, delta)

func physics_update(delta: float) -> void:
	PLAYER.update_gravity(delta)
	PLAYER.update_input(SPEED, ACCELERATION, DECELERATION)
	PLAYER.update_velocity()

	if Input.is_action_just_pressed(PLAYER.STATES.JUMP.ACTION):
		if _not_previously_jumping():
			transition.emit(PLAYER.STATES.JUMP.NAME)
		elif _previous_state is PlayerJumpState:
			transition.emit(PLAYER.STATES.DOUBLE_JUMP.NAME)

	if PLAYER.is_on_floor():
		transition.emit(PLAYER.STATES.IDLE.NAME)

func _not_previously_jumping() -> bool:
	return !(_previous_state is PlayerJumpState ||
				_previous_state is PlayerDoubleJumpState)
