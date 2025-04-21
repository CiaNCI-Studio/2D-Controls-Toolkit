extends BaseControler2D
class_name TopDownControler2D

enum action_types {
	directional,
	move_to_click
}

@export_category("Movement")
@export var Action_Type : action_types = action_types.directional
@export var Rotate = true
@export var Turn_Speed = 10
@export var Floor_Group : String = "floor"

@export_category("Camera")
@export var Handle_Camera : bool = true
@export var Camera_Smooth_Distance : float = 0
@export var Camera_Smooth_Speed : float = 0
@export var camera_zoom : Vector2 = Vector2(1, 1)
@export var Angle : float = -70
@export var Horizontal_Offset : float = 0
@export var Vertical_Offset : float = 0
@export var Custom_Camera : Camera2D

var pivot : Node2D 
var camera : Camera2D 
var camera_rest_position : Vector2
var use_pivot = true
var target = Vector2.ZERO

func _ready() -> void:
	if Handle_Camera:
		if Custom_Camera:
			camera = Custom_Camera
			use_pivot = false
		else:
			pivot = Node2D.new()
			add_child(pivot)
			pivot.position.x = Horizontal_Offset
			pivot.position.y = Vertical_Offset				
			camera = Camera2D.new()		
			camera.zoom = camera_zoom
			pivot.add_child(camera)				
			use_pivot = true	
	
	if Action_Type == action_types.move_to_click:
		var floors = get_tree().get_nodes_in_group(Floor_Group)
		for floor in floors:
			floor.connect("input_event", on_floor_input)	
				
	toggle_active(Active)
			
func on_floor_input(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if not Active or Action_Type == action_types.directional:
		return
	if event is InputEventMouseButton and event.pressed:
		target = event_position

func _process(delta: float) -> void:
	if not Active:
		return	
	
	match Action_Type:
		action_types.directional:
			handle_directional_action(delta)
		action_types.move_to_click:
			handle_move_to_click_action(delta)
	move()

	
func handle_directional_action(delta :float):
	var direction = get_direction()
	var currentSpeed = get_speed()
	if direction:
		velocity.x = move_toward(velocity.x, direction.x * currentSpeed, Acceleration * delta)
		velocity.y = move_toward(velocity.y, direction.y * currentSpeed, Acceleration * delta)		
		if Handle_Camera:
			if use_pivot:		
				if Camera_Smooth_Distance and abs(pivot.position.x) < Camera_Smooth_Distance:	
					pivot.position.x = move_toward(pivot.position.x, direction.x * currentSpeed * -1, Camera_Smooth_Speed * delta)
				if Camera_Smooth_Distance and abs(pivot.position.y) < Camera_Smooth_Distance:	
					pivot.position.y = move_toward(pivot.position.y, direction.y * currentSpeed * -1, Camera_Smooth_Speed * delta)
			else:
				if Camera_Smooth_Distance and abs(camera.position.x) < Camera_Smooth_Distance:	
					camera.position.x = move_toward(camera.position.x, direction.x * currentSpeed * -1, Camera_Smooth_Speed * delta)
				if Camera_Smooth_Distance and abs(camera.position.y) < Camera_Smooth_Distance:	
					camera.position.y = move_toward(camera.position.y, direction.y * currentSpeed * -1, Camera_Smooth_Speed * delta)
		handle_rotation(delta, direction)
			
	else:		
		velocity.x = move_toward(velocity.x, 0, Deacceleration * delta)		
		velocity.y = move_toward(velocity.y, 0, Deacceleration * delta)		
		if Camera_Smooth_Distance and Handle_Camera:
			if use_pivot:		
				pivot.position.x = move_toward(pivot.position.x, Horizontal_Offset, Camera_Smooth_Speed * delta)
				pivot.position.y = move_toward(pivot.position.y, Horizontal_Offset, Camera_Smooth_Speed * delta)
			else:
				camera.position.x = move_toward(camera.position.x, Horizontal_Offset, Camera_Smooth_Speed * delta)
				camera.position.y = move_toward(camera.position.y, Horizontal_Offset, Camera_Smooth_Speed * delta)		
	
func handle_move_to_click_action(delta :float):
	var currentSpeed = get_speed()
	
	if target:
		var direction = parent.global_position.direction_to(target)
		
		if direction:
			velocity.x = move_toward(velocity.x, direction.x * currentSpeed, Acceleration * delta)
			velocity.y = move_toward(velocity.y, direction.y * currentSpeed, Acceleration * delta)
			handle_rotation(delta, direction)	
		else:
			velocity.x = move_toward(velocity.x, 0, Deacceleration * delta)		
			velocity.y = move_toward(velocity.y, 0, Deacceleration * delta)	
			
		if transform.origin.distance_to(target) < .5:
			target = Vector2.ZERO			

func handle_rotation(delta : float, direction : Vector2):
	if Rotate:
		var currentRotation = parent.rotation
		parent.look_at( parent.global_position + direction)
		var targetRotation = parent.rotation
		parent.rotation = lerp_angle(currentRotation, targetRotation, Turn_Speed * delta)

func toggle_active(state : bool):	
	Active = state
	if Handle_Camera:
		if state:
			camera.make_current()
		else:
			camera.clear_current()
