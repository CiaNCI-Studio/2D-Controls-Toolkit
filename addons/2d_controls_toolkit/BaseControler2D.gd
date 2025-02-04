extends Node2D
class_name BaseControler2D

#Types
enum movement_types {
	MoveAndSlide,
	MoveAndCollide,
	None
}

#Signals
signal hit_ceiling
signal ChangeSpriteDirection(Vector2)

@export var Active : bool = true
@export_category("Inputs")
@export var Input_Up = "up"
@export var Input_Down = "down"
@export var Input_Left = "left"
@export var Input_Right = "right"
@export var Input_Sprint = "sprint"
@export var Input_Jump = "jump"
@export var Input_Cancel = "ui_cancel"
@export_category("Movement")
@export var Speed_Walk = 400.0
@export var Speed_Sprint = 600.0
@export var Acceleration = 1000
@export var Deacceleration = 1400
@export var Movement_Type : movement_types = movement_types.MoveAndSlide
@export var Handle_Gravity : bool = true
@export var Handle_Mouse_Capture : bool = true
@export var Air_Control : bool = true

var sprinting = false
var jumping = false
var velocity : Vector2 = Vector2.ZERO
var coyote_timer : float = 0
var jump_buffer_timer : float = 0
var last_direction : Vector2

@onready var parent = get_parent() as CharacterBody2D

func get_direction(refernce : Node2D = parent) -> Vector2:
	var current = last_direction
	if (not jumping or Air_Control):
		var input_dir = Input.get_vector(Input_Left, Input_Right, Input_Up, Input_Down)
		last_direction = (refernce.transform.origin * Vector2(input_dir.x, input_dir.y)).normalized()
	if current != last_direction:
		ChangeSpriteDirection.emit(last_direction)
	return last_direction

func get_speed() -> float:
	var currentSpeed = Speed_Walk
	if Input_Sprint != "" and Input.is_action_pressed(Input_Sprint):
		currentSpeed = Speed_Sprint
	return currentSpeed
			
func move():
	if Active:
		if Movement_Type == movement_types.MoveAndSlide:
			parent.velocity = velocity
			parent.move_and_slide()
		elif Movement_Type == movement_types.MoveAndCollide:
			parent.move_and_collide(velocity)
