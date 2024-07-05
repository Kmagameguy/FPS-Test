class_name PlayerCrouchState extends PlayerMovementState

@export var SPEED       : float = 3.0
@export var ACCELERATION: float = 0.1
@export var DECELERATION: float = 0.25
@export_range(1, 6, 0.1) var CROUCH_SPEED: float = 4.0

@onready var CROUCH_SHAPECAST: ShapeCast3D = %CrouchCollisionShapecast

# These aren't really necessary,
# just using them as labels to make the intent of the
# calls to PLAYER.handle_crouch more intention revealing.
var _crouched = true
var _uncrouched = false

func update(delta) -> void:
	PLAYER.update_gravity(delta)
	PLAYER.handle_crouch(_crouched)
	PLAYER.update_input(SPEED, ACCELERATION, DECELERATION)
	PLAYER.update_velocity()
	
	if !Input.is_action_pressed(PLAYER.STATES.CROUCH.ACTION):
		uncrouch()
		transition.emit(PLAYER.STATES.IDLE.NAME)
	
	if PLAYER.velocity.y < -1.0 && PLAYER.is_in_air():
		uncrouch()
		transition.emit(PLAYER.STATES.FALL.NAME)

func uncrouch() -> void:
	if !CROUCH_SHAPECAST.is_colliding() && !Input.is_action_pressed(PLAYER.STATES.CROUCH.ACTION):
		PLAYER.handle_crouch(_uncrouched)
	elif CROUCH_SHAPECAST.is_colliding():
		await get_tree().create_timer(0.1).timeout
		uncrouch()
