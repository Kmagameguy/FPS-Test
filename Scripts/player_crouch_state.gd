class_name PlayerCrouchState extends PlayerMovementState

@export var SPEED       : float = 2.0
@export var ACCELERATION: float = 0.1
@export var DECELERATION: float = 0.25

func enter(_previous_state: PlayerState) -> void:
	PLAYER.set_stance_height(PLAYER.CROUCH_HEIGHT)

func update(delta: float) -> void:
	PLAYER.update_headbob(delta)
	PLAYER.update_fov(SPEED, delta)

func physics_update(delta: float) -> void:
	PLAYER.update_gravity(delta)
	PLAYER.update_input(SPEED, ACCELERATION, DECELERATION)
	PLAYER.update_velocity()
	
	if !Input.is_action_pressed(PLAYER.STATES.CROUCH.ACTION) && PLAYER.can_stand_up():
		if PLAYER.velocity.length() > 0.0:
			transition.emit(PLAYER.STATES.WALK.NAME)
		else:
			transition.emit(PLAYER.STATES.IDLE.NAME)
	
	if PLAYER.velocity.y < PLAYER.FALL_VELOCITY_THRESHOLD && PLAYER.is_in_air():
		transition.emit(PLAYER.STATES.FALL.NAME)
