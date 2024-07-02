class_name PlayerMovementState extends PlayerState

var PLAYER: Player

func _ready() -> void:
	await owner.ready
	PLAYER = owner as Player
