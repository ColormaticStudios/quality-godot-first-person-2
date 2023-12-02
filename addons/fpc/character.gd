extends CharacterBody3D

# TODO: Add descriptions for each value

@export_category("Character")
@export var base_speed : float = 3.0
@export var sprint_speed : float = 6.0
@export var crouch_speed : float = 1.0

@export var acceleration : float = 10.0
@export var jump_velocity : float = 4.5
@export var mouse_sensitivity : float = 0.1

@export_group("Nodes")
@export var HEAD : Node3D
@export var CAMERA : Camera3D
@export var CAMERA_ANIMATION : AnimationPlayer

@export_group("Controls")
# We are using UI controls because they are built into Godot Engine so they can be used right away
@export var JUMP : String = "ui_accept"
@export var LEFT : String = "ui_left"
@export var RIGHT : String = "ui_right"
@export var FORWARD : String = "ui_up"
@export var BACKWARD : String = "ui_down"
@export var PAUSE : String = "ui_cancel"
@export var CROUCH : String
@export var SPRINT : String

@export_group("Feature Settings")
@export var immobile : bool = false
@export var jumping_enabled : bool = true
@export var in_air_momentum : bool = true
@export var motion_smoothing : bool = true
@export var sprint_enabled : bool = true
@export var crouch_enabled : bool = true
@export_enum("Hold to Crouch", "Toggle Crouch") var crouch_mode : int = 0
@export_enum("Hold to Sprint", "Toggle Sprint") var sprint_mode : int = 0
@export var dynamic_fov : bool = true
@export var continuous_jumping : bool = true
@export var view_bobbing : bool = true

# Member variables
var speed : float = base_speed
var is_crouching : bool = false
var is_sprinting : bool = false

# Get the gravity from the project settings to be synced with RigidBody nodes
var gravity : float = ProjectSettings.get_setting("physics/3d/default_gravity") # Don't set this as a const, see the gravity section in _physics_process


func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta):
	
	# Add some debug data
	$UserInterface/DebugPanel.add_property("Movement Speed", speed, 1)
	$UserInterface/DebugPanel.add_property("Velocity", get_real_velocity(), 2)
	
	# Gravity
	#gravity = ProjectSettings.get_setting("physics/3d/default_gravity") # If the gravity changes during your game, uncomment this code
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	handle_jumping()
	
	var input_dir = Vector2.ZERO
	if !immobile:
		input_dir = Input.get_vector(LEFT, RIGHT, FORWARD, BACKWARD)
	
	handle_movement(delta, input_dir)
	
	toggle_crouch()
	toggle_sprint(input_dir)
	
	if is_crouching:
		speed = crouch_speed
	elif is_sprinting:
		speed = sprint_speed
	else:
		speed = base_speed
	
	
	if view_bobbing:
		headbob_animation(input_dir)


func handle_jumping():
	if jumping_enabled:
		if continuous_jumping:
			if Input.is_action_pressed(JUMP) and is_on_floor():
				velocity.y += jump_velocity
		else:
			if Input.is_action_just_pressed(JUMP) and is_on_floor():
				velocity.y += jump_velocity

func handle_movement(delta, input_dir):
	
	var direction = input_dir.rotated(-HEAD.rotation.y)
	direction = Vector3(direction.x, 0, direction.y)
	
	move_and_slide()
	
	if in_air_momentum:
		if is_on_floor(): # Don't lerp y movement
			if motion_smoothing:
				velocity.x = lerp(velocity.x, direction.x * speed, acceleration * delta)
				velocity.z = lerp(velocity.z, direction.z * speed, acceleration * delta)
			else:
				velocity.x = direction.x * speed
				velocity.z = direction.z * speed
	else:
		if motion_smoothing:
			velocity.x = lerp(velocity.x, direction.x * speed, acceleration * delta)
			velocity.z = lerp(velocity.z, direction.z * speed, acceleration * delta)
		else:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed


func _process(delta):
	
	$UserInterface/DebugPanel.add_property("FPS", 1.0/delta, 0)
	
	if Input.is_action_just_pressed(PAUSE):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		elif Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event):
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		HEAD.rotation_degrees.y -= event.relative.x * mouse_sensitivity
		HEAD.rotation_degrees.x -= event.relative.y * mouse_sensitivity
		HEAD.rotation.x = clamp(HEAD.rotation.x, deg_to_rad(-90), deg_to_rad(90))


func toggle_crouch():
	if crouch_enabled:
		if crouch_mode == 0:
			is_crouching = Input.is_action_pressed(CROUCH)
		elif crouch_mode == 1:
			if Input.is_action_just_pressed(CROUCH):
				is_crouching = !is_crouching
	
		# Replace with your own crouch animation code
		if is_crouching:
			$Collision.scale.y = lerp($Collision.scale.y, 0.75, 0.2)
		else:
			$Collision.scale.y = lerp($Collision.scale.y, 1.0, 0.2)


func toggle_sprint(moving):
	if sprint_enabled:
		if sprint_mode == 0:
			if !is_crouching: # Crouching takes priority over sprinting
				is_sprinting = Input.is_action_pressed(SPRINT)
			else:
				is_sprinting = false # Fix a bug where if you are sprinting and then crouch then let go of the sprinting button you keep sprinting
		elif sprint_mode == 1:
			if Input.is_action_just_pressed(SPRINT):
				if !is_crouching:
					is_sprinting = !is_sprinting
				else:
					is_sprinting = false
	
		if dynamic_fov:
			if is_sprinting and moving:
				CAMERA.fov = lerp(CAMERA.fov, 85.0, 0.3)
			else:
				CAMERA.fov = lerp(CAMERA.fov, 75.0, 0.3)


func headbob_animation(moving):
	if moving and is_on_floor():
		CAMERA_ANIMATION.play("headbob")
		CAMERA_ANIMATION.speed_scale = speed / base_speed
	else:
		CAMERA_ANIMATION.play("RESET")
