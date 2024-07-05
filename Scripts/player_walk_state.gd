class_name PlayerWalkState extends PlayerMovementState

@export var SPEED       : float = 5.0
@export var ACCELERATION: float = 0.1
@export var DECELERATION: float = 0.25

func update(delta: float) -> void:
	PLAYER.update_gravity(delta)
	PLAYER.update_input(SPEED, ACCELERATION, DECELERATION)
	PLAYER.update_velocity()

	if Input.is_action_pressed(PLAYER.STATES.SPRINT.ACTION) && PLAYER.is_on_floor():
		transition.emit(PLAYER.STATES.SPRINT.NAME)

	if Input.is_action_pressed(PLAYER.STATES.TIP_TOE.ACTION) && PLAYER.is_on_floor():
		transition.emit(PLAYER.STATES.TIP_TOE.NAME)
	
	if Input.is_action_pressed(PLAYER.STATES.JUMP.ACTION) && PLAYER.is_on_floor():
		transition.emit(PLAYER.STATES.JUMP.NAME)
	
	if Input.is_action_pressed(PLAYER.STATES.CROUCH.ACTION) && PLAYER.is_on_floor():
		transition.emit(PLAYER.STATES.CROUCH.NAME)

	if PLAYER.velocity.length() == 0.0:
		transition.emit(PLAYER.STATES.IDLE.NAME)

	if PLAYER.velocity.y < -3.0 && PLAYER.is_in_air():
		transition.emit(PLAYER.STATES.FALL.NAME)

func physics_update(delta: float) -> void:
	PLAYER.update_headbob(delta)
	PLAYER.update_fov(SPEED, delta)
