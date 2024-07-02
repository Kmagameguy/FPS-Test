class_name PlayerJumpState extends PlayerMovementState

@export var SPEED        : float = 6.5
@export var ACCELERATION : float = 0.1
@export var DECELERATION : float = 0.25
@export var JUMP_VELOCITY: float = 4.5
@export_range(0.5, 1.0, 0.01) var INPUT_REDUCER: float = 0.85

func enter(_previous_state: PlayerState) -> void:
	PLAYER.velocity.y = JUMP_VELOCITY

func update(delta: float) -> void:
	PLAYER.update_gravity(delta)
	PLAYER.update_input(SPEED * INPUT_REDUCER, ACCELERATION, DECELERATION)
	PLAYER.update_velocity()

	if Input.is_action_just_released(PLAYER.STATES.JUMP.ACTION):
		if PLAYER.velocity.y > 0:
			PLAYER.velocity.y = PLAYER.velocity.y / 2.0

	if Input.is_action_just_pressed(PLAYER.STATES.DOUBLE_JUMP.ACTION) && PLAYER.is_in_air():
		transition.emit(PLAYER.STATES.DOUBLE_JUMP.NAME)

	if PLAYER.is_on_floor():
		transition.emit(PLAYER.STATES.IDLE.NAME)

	if PLAYER.velocity.y < -4.0 && PLAYER.is_in_air():
		transition.emit(PLAYER.STATES.FALL.NAME)
