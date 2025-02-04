extends BaseControler2D
class_name SideScrollingControler2D

signal sprint_start
signal sprint_end
signal jump_start
signal jump_cancel
signal jump_end

@export_category("Camera")
@export var Handle_Camera : bool = true
@export var Camera_Smooth_Distance : float = 1
@export var Camera_Smooth_Speed : float = 5
@export var Camera_LookAt_Player: bool = true
@export var Camera_Lock_Y_Rotation: bool = true
@export var Camera_Max_Boundary: Vector2 = Vector2.ZERO
@export var Camera_Min_Boundary: Vector2 = Vector2.ZERO
@export var camera_zoom : Vector2 = Vector2(1, 1)
@export var Horizontal_Offset : float = 0
@export var Vertical_Offset : float = 0
@export var Custom_Camera : Camera2D

@export_category("Jump")
@export var Can_Jump : bool = true
@export var Variable_Jump : bool = true
@export var Jump_Height = 100.0
@export var Jump_Time_To_Peak = 0.4
@export var Jump_Time_To_Descend = 0.2
@export var Coyote_Time = 0.2
@export var Jump_Buffer_Time = 0.2


@onready var jump_velocity = (2.0 * Jump_Height) / Jump_Time_To_Peak
@onready var jump_gravity = (-2.0 * Jump_Height) / (Jump_Time_To_Peak * Jump_Time_To_Peak)
@onready var fall_gravity = (-2.0 * Jump_Height) / (Jump_Time_To_Descend * Jump_Time_To_Descend)

var pivot : Node2D 
var camera : Camera2D 
var camera_rest_position : Vector2
var use_pivot = true

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
			pivot.add_child(camera)	
			camera.zoom = camera_zoom
			use_pivot = true
		
				
	toggle_active(Active)

func _process(delta: float) -> void:
	if not Active:
		return
		
	handle_gravity(delta)
	HandleJump(delta)			
	var direction = get_direction()
	var currentSpeed = get_speed()
			
	if direction:
		velocity.x = move_toward(velocity.x, direction.x * currentSpeed, Acceleration * delta)
		if Handle_Camera:
			if use_pivot:		
				if Camera_Smooth_Distance and abs(pivot.position.x) < Camera_Smooth_Distance:	
					pivot.position.x = move_toward(pivot.position.x, direction.x * currentSpeed * -1, Camera_Smooth_Speed * delta)
			else:
				if Camera_Smooth_Distance and abs(camera.position.x) < Camera_Smooth_Distance:	
					camera.position.x = move_toward(camera.position.x, direction.x * currentSpeed * -1, Camera_Smooth_Speed * delta)
	else:		
		velocity.x = move_toward(velocity.x, 0, Deacceleration * delta)		
		if Camera_Smooth_Distance and Handle_Camera:		
			if use_pivot:		
				pivot.position.x = move_toward(pivot.position.x, Horizontal_Offset, Camera_Smooth_Speed * delta)
			else:
				camera.position.x = move_toward(camera.position.x, Horizontal_Offset, Camera_Smooth_Speed * delta)
					
	if Handle_Camera:
		if Camera_LookAt_Player:
			camera.look_at(parent.global_position)		
		if Camera_Max_Boundary and Camera_Min_Boundary:
			if use_pivot:	
				if pivot.global_position.x > Camera_Max_Boundary.x and Camera_Max_Boundary.x != 0:
					pivot.global_position.x = Camera_Max_Boundary.x
				elif pivot.global_position.x < Camera_Min_Boundary.x and Camera_Min_Boundary.x != 0:
					pivot.global_position.x = Camera_Min_Boundary.x
				if pivot.global_position.y > Camera_Max_Boundary.y and Camera_Max_Boundary.y != 0:
					pivot.global_position.y = Camera_Max_Boundary.y
				elif pivot.global_position.y < Camera_Min_Boundary.y and Camera_Min_Boundary.y != 0:
					pivot.global_position.y = Camera_Min_Boundary.y										
			else:
				if camera.global_position.x > Camera_Max_Boundary.x and Camera_Max_Boundary.x != 0:
					camera.global_position.x = Camera_Max_Boundary.x
				elif camera.global_position.x < Camera_Min_Boundary.x and Camera_Min_Boundary.x != 0:
					camera.global_position.x = Camera_Min_Boundary.x
				if camera.global_position.y > Camera_Max_Boundary.y and Camera_Max_Boundary.y != 0:
					camera.global_position.y = Camera_Max_Boundary.y
				elif camera.global_position.y < Camera_Min_Boundary.y and Camera_Min_Boundary.y != 0:
					camera.global_position.y = Camera_Min_Boundary.y				
	
	move()


func get_gravity() -> Vector2:
	if Can_Jump:
		return Vector2(0, jump_gravity if velocity.y < 0.0 else fall_gravity)
	else:
		return parent.get_gravity()

func handle_gravity(delta : float):
	if Handle_Gravity and not parent.is_on_floor():
		velocity += (get_gravity() * delta) * -1
	else:
		velocity.y = 0
	
func HandleJump(delta : float) -> void:
	
	if not Can_Jump or not Active:
		return
		
	if parent.is_on_floor():
		coyote_timer = Coyote_Time;
		if jumping:
			emit_signal("jump_end")
		jumping = false
	elif coyote_timer > 0: 
		coyote_timer -= delta
	else:
		coyote_timer = 0 
		
	if jump_buffer_timer > 0: 
		jump_buffer_timer -= delta
	else:
		jump_buffer_timer = 0 
	
	var do_jump = false
		
	if Input.is_action_just_pressed(Input_Jump) and coyote_timer > 0 and not jumping:
		do_jump = true
	elif Input.is_action_just_pressed(Input_Jump) and not parent.is_on_floor() and Jump_Buffer_Time > 0:
		jump_buffer_timer = Jump_Buffer_Time
	elif Input.is_action_just_pressed(Input_Jump) and parent.is_on_floor() and Jump_Buffer_Time <= 0:
		do_jump = true
		
	if parent.is_on_floor() and jump_buffer_timer > 0 and not jumping:
		jump_buffer_timer = 0 
		do_jump = true			
	
	if do_jump:
		jumping = true
		emit_signal("jump_start")
		velocity.y = jump_velocity * -1
		
	if (parent.is_on_ceiling() and velocity.y > 0) :
		emit_signal("hit_ceiling")
		velocity.y = 0
	if (Input.is_action_just_released(Input_Jump) and Variable_Jump and jumping) :
		emit_signal("jump_cancel")
		velocity.y = 0
		
func toggle_active(state : bool):
	Active = state
	if Handle_Camera:
		if state:		
			camera.make_current()
		else:		
			camera.clear_current()
