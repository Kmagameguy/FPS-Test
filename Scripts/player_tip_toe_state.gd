class_name PlayerTipToeState extends PlayerMovementState

@export var SPEED       : float = 2.0
@export var ACCELERATION: float = 0.1
@export var DECELERATION: float = 0.25

func update(delta: float) -> void:
	PLAYER.update_gravity(delta)
	PLAYER.update_input(SPEED, ACCELERATION, DECELERATION)
	PLAYER.update_velocity()

	if Input.is_action_just_released(PLAYER.STATES.TIP_TOE.ACTION):
		transition.emit(PLAYER.STATES.WALK.NAME)

	if Input.is_action_just_pressed(PLAYER.STATES.JUMP.ACTION):
		transition.emit(PLAYER.STATES.JUMP.NAME)

	if PLAYER.velocity.length() == 0.0 && PLAYER.is_on_floor():
		transition.emit(PLAYER.STATES.IDLE.NAME)

	if PLAYER.velocity.y < -3.0 && PLAYER.is_in_air():
		transition.emit(PLAYER.STATES.FALL.NAME)

func update_physics(delta: float) -> void:
	PLAYER.update_headbob(delta)
	PLAYER.update_fov(SPEED, delta)
