# COPYRIGHT Colormatic Studios
# MIT license
# Quality Godot First Person Controller v2


extends CharacterBody3D
class_name Character


#region Character Export Group

## The settings for the character's movement and feel.
@export_category("Character")
## The speed that the character moves at without crouching or sprinting.
@export var base_speed : float = 3.0
## The speed that the character moves at when sprinting.
@export var sprint_speed : float = 6.0
## The speed that the character moves at when crouching.
@export var crouch_speed : float = 1.0

## How fast the character speeds up and slows down when Motion Smoothing is on.
@export var acceleration : float = 10.0
## How high the player jumps.
@export var jump_velocity : float = 4.5
## How far the player turns when the mouse is moved.
@export var mouse_sensitivity : float = 0.1
## Invert the X axis input for the camera.
@export var invert_camera_x_axis : bool = false
## Invert the Y axis input for the camera.
@export var invert_camera_y_axis : bool = false
## Whether the player can use movement inputs. Does not stop outside forces or jumping. See Jumping Enabled.
@export var immobile : bool = false
## The reticle file to import at runtime. By default are in res://addons/fpc/reticles/. Set to an empty string to remove.
@export_file var default_reticle

#endregion

#region Nodes Export Group

@export_group("Nodes")
## A reference to the camera for use in the character script. This is the parent node to the camera and is rotated instead of the camera for mouse input.
@export var HEAD : Node3D
## A reference to the camera for use in the character script.
@export var CAMERA : Camera3D
## A reference to the headbob animation for use in the character script.
@export var HEADBOB_ANIMATION : AnimationPlayer
## A reference to the jump animation for use in the character script.
@export var JUMP_ANIMATION : AnimationPlayer
## A reference to the crouch animation for use in the character script.
@export var CROUCH_ANIMATION : AnimationPlayer
## A reference to the the player's collision shape for use in the character script.
@export var COLLISION_MESH : CollisionShape3D

#endregion

#region Controls Export Group

# We are using UI controls because they are built into Godot Engine so they can be used right away
@export_group("Controls")
## Use the Input Map to map a mouse/keyboard input to an action and add a reference to it to this dictionary to be used in the script.
@export var controls : Dictionary = {
	LEFT = "ui_left",
	RIGHT = "ui_right",
	FORWARD = "ui_up",
	BACKWARD = "ui_down",
	JUMP = "ui_accept",
	CROUCH = "crouch",
	SPRINT = "sprint",
	PAUSE = "ui_cancel"
	}
@export_subgroup("Controller Specific")
## This only affects how the camera is handled, the rest should be covered by adding controller inputs to the existing actions in the Input Map.
@export var controller_support : bool = false
## Use the Input Map to map a controller input to an action and add a reference to it to this dictionary to be used in the script.
@export var controller_controls : Dictionary = {
	LOOK_LEFT = "look_left",
	LOOK_RIGHT = "look_right",
	LOOK_UP = "look_up",
	LOOK_DOWN = "look_down"
	}
## The sensitivity of the analog stick that controls camera rotation. Lower is less sensitive and higher is more sensitive.
@export_range(0.001, 0.1, 0.001) var look_sensitivity : float = 0.035

#endregion

#region Feature Settings Export Group

@export_group("Feature Settings")
## Enable or disable jumping. Useful for restrictive storytelling environments.
@export var jumping_enabled : bool = true
## Whether the player can move in the air or not.
@export var in_air_momentum : bool = true
## Smooths the feel of walking.
@export var motion_smoothing : bool = true
## Enables or disables sprinting.
@export var sprint_enabled : bool = true
## Toggles the sprinting state when button is pressed or requires the player to hold the button down to remain sprinting.
@export_enum("Hold to Sprint", "Toggle Sprint") var sprint_mode : int = 0
## Enables or disables crouching.
@export var crouch_enabled : bool = true
## Toggles the crouch state when button is pressed or requires the player to hold the button down to remain crouched.
@export_enum("Hold to Crouch", "Toggle Crouch") var crouch_mode : int = 0
## Wether sprinting should effect FOV.
@export var dynamic_fov : bool = true
## If the player holds down the jump button, should the player keep hopping.
@export var continuous_jumping : bool = true
## Enables the view bobbing animation.
@export var view_bobbing : bool = true
## Enables an immersive animation when the player jumps and hits the ground.
@export var view_tilting : bool = false
## Enables an immersive "view tilting" effect when the player turns their head.
@export var jump_animation : bool = true
## This determines wether the player can use the pause button, not wether the game will actually pause.
@export var pausing_enabled : bool = true
## Use with caution.
@export var gravity_enabled : bool = true

#endregion

#region Member Variable Initialization

# These are variables used in this script that don't need to be exposed in the editor.
var speed : float = base_speed
var current_speed : float = 0.0
# States: normal, crouching, sprinting
var state : String = "normal"
var low_ceiling : bool = false # This is for when the ceiling is too low and the player needs to crouch.
var was_on_floor : bool = true # Was the player on the floor last frame (for landing animation)

# The reticle should always have a Control node as the root
var RETICLE : Control

# Accumulates mouse input until the next camera rotation (on Web, only the latest event, see web_mouse_workaround)
var mouse_input : Vector2 = Vector2(0,0)

# Workaround for camera jumps in web exports (6dfad6e): in Chrome on Windows, pointer lock sometimes reports false
# mouse motion of almost half the window size in one event. On Web, input accumulation is disabled (see _ready) and
# only the latest mouse motion event is used (see _unhandled_input). This hides most of the false motion, but also
# loses real motion when several events arrive before the next camera rotation.
var web_mouse_workaround : bool = OS.get_name() == "Web"

# View tilting measures the head turn over intervals of at least 1/60 s and one frame (see _handle_head_rotation)
var tilt_turned : float = 0.0
var tilt_time : float = 0.0
var target_tilt : float = 0.0

# Stores horizontal movement input
var input_dir : Vector2 = Vector2.ZERO
# Whether or not the player is moving
var moving : bool = false

#endregion



#region Main Control Flow

func _ready() -> void:
	# It is safe to comment this line if your game doesn't start with the mouse captured
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	# If the controller is rotated in a certain direction for game design purposes, redirect this rotation into the head.
	HEAD.rotation.y = rotation.y
	rotation.y = 0

	# With physics interpolation, the head is rotated every rendered frame (see _process), so it must not be
	# physics-interpolated itself. It still follows the interpolated body. A mode set in the scene is kept.
	if HEAD.physics_interpolation_mode == Node.PHYSICS_INTERPOLATION_MODE_INHERIT:
		HEAD.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF

	if default_reticle:
		change_reticle(default_reticle)

	_initialize_animations()
	_check_controls()
	_enter_normal_state()

	if web_mouse_workaround:
		Input.set_use_accumulated_input(false)


func _process(delta : float) -> void:
	if pausing_enabled:
		_handle_pausing()

	# With physics interpolation, the body is drawn between physics ticks, so the camera is rotated every rendered frame.
	# Without it, or if the head is interpolated (a mode set in the scene), the camera is rotated on physics ticks.
	if is_physics_interpolated_and_enabled() and not HEAD.is_physics_interpolated():
		_handle_head_rotation(delta)

	if dynamic_fov: # This may be changed to an AnimationPlayer
		_update_camera_fov()

	_update_debug_menu_per_frame()


func _physics_process(delta : float) -> void:
	if not is_on_floor() and gravity_enabled:
		velocity += get_gravity() * delta

	_handle_jumping()

	input_dir = Vector2.ZERO

	if not immobile: # Immobility works by interrupting user input, so other forces can still be applied to the player
		input_dir = Input.get_vector(controls.LEFT, controls.RIGHT, controls.FORWARD, controls.BACKWARD)

	moving = input_dir != Vector2.ZERO

	_handle_movement(delta, input_dir)
	current_speed = Vector3.ZERO.distance_to(get_real_velocity())

	if not is_physics_interpolated_and_enabled() or HEAD.is_physics_interpolated(): # Otherwise it is rotated in _process
		_handle_head_rotation(delta)

	# The player is not able to stand up if the ceiling is too low
	low_ceiling = $CrouchCeilingDetection.is_colliding()

	_handle_state(moving)

	if view_bobbing:
		_play_headbob_animation(moving)

	if jump_animation:
		_play_jump_animation()

	_update_debug_menu_per_tick()

	was_on_floor = is_on_floor() # This must always be at the end of physics_process

#endregion

#region Input Handling

func _handle_jumping() -> void:
	if jumping_enabled:
		if continuous_jumping: # Hold down the jump button
			if Input.is_action_pressed(controls.JUMP) and is_on_floor() and !low_ceiling and velocity.y <= 0.0: # Not while still rising, so jumps can't stack
				if jump_animation:
					JUMP_ANIMATION.play("jump", 0.25)
				velocity.y += jump_velocity # Adding instead of setting so jumping on slopes works properly
		else:
			if Input.is_action_just_pressed(controls.JUMP) and is_on_floor() and !low_ceiling and velocity.y <= 0.0:
				if jump_animation:
					JUMP_ANIMATION.play("jump", 0.25)
				velocity.y += jump_velocity


func _handle_movement(delta : float, input_dir : Vector2) -> void:
	var direction2D := input_dir.rotated(-HEAD.rotation.y)
	var direction3D := Vector3(direction2D.x, 0, direction2D.y)
	move_and_slide()

	if in_air_momentum:
		if is_on_floor():
			if motion_smoothing:
				velocity.x = lerp(velocity.x, direction3D.x * speed, acceleration * delta)
				velocity.z = lerp(velocity.z, direction3D.z * speed, acceleration * delta)
			else:
				velocity.x = direction3D.x * speed
				velocity.z = direction3D.z * speed
	else:
		if motion_smoothing:
			velocity.x = lerp(velocity.x, direction3D.x * speed, acceleration * delta)
			velocity.z = lerp(velocity.z, direction3D.z * speed, acceleration * delta)
		else:
			velocity.x = direction3D.x * speed
			velocity.z = direction3D.z * speed


func _handle_head_rotation(delta : float) -> void:
	var yaw_before : float = HEAD.rotation.y # For view tilting, which follows how fast the head turns

	if invert_camera_x_axis:
		HEAD.rotation_degrees.y -= mouse_input.x * mouse_sensitivity * -1
	else:
		HEAD.rotation_degrees.y -= mouse_input.x * mouse_sensitivity

	if invert_camera_y_axis:
		HEAD.rotation_degrees.x -= mouse_input.y * mouse_sensitivity * -1
	else:
		HEAD.rotation_degrees.x -= mouse_input.y * mouse_sensitivity

	if controller_support:
		# look_sensitivity is the turn in 1/60 s, so it is scaled by delta to keep the stick speed the same at any FPS
		var controller_view_rotation = Input.get_vector(controller_controls.LOOK_DOWN, controller_controls.LOOK_UP, controller_controls.LOOK_RIGHT, controller_controls.LOOK_LEFT) * look_sensitivity * delta * 60.0 # These are inverted because of the nature of 3D rotation.
		if invert_camera_y_axis:
			HEAD.rotation.x += controller_view_rotation.x * -1
		else:
			HEAD.rotation.x += controller_view_rotation.x

		if invert_camera_x_axis:
			HEAD.rotation.y += controller_view_rotation.y * -1
		else:
			HEAD.rotation.y += controller_view_rotation.y

	if view_tilting:
		# The tilt is 1.5x the degrees the head turns in 1/60 s. The turn is measured over intervals of at least 1/60 s
		# and one rendered frame, so the tilt does not depend on the frame rate or on how often the mouse reports motion.
		if delta > 0.0: # At Engine.time_scale 0, turns are not added up, so the tilt does not jump when time resumes
			tilt_turned += rad_to_deg(angle_difference(yaw_before, HEAD.rotation.y))
			tilt_time += delta
		if tilt_time >= maxf(1.0 / 60.0, get_process_delta_time()):
			target_tilt = clampf(tilt_turned / (tilt_time * 60.0) * 1.5, -5.0, 5.0)
			tilt_turned = 0.0
			tilt_time = 0.0
		HEAD.rotation_degrees.z = lerpf(
			HEAD.rotation_degrees.z,
			target_tilt,
			1.0 - exp(-12.0 * delta) # Change -12.0 to adjust tilt responsiveness: lower is floatier, higher is snappier
		)

	mouse_input = Vector2.ZERO
	HEAD.rotation_degrees.x = clamp(HEAD.rotation_degrees.x, -90, 90)


func _check_controls() -> void: # If you add a control, you might want to add a check for it here.
	# The actions are being disabled so the engine doesn't halt the entire game in debug mode
	if !InputMap.has_action(controls.JUMP):
		push_error("No control mapped for jumping. Please add an input map control. Disabling jump.")
		jumping_enabled = false
	if !InputMap.has_action(controls.LEFT):
		push_error("No control mapped for move left. Please add an input map control. Disabling movement.")
		immobile = true
	if !InputMap.has_action(controls.RIGHT):
		push_error("No control mapped for move right. Please add an input map control. Disabling movement.")
		immobile = true
	if !InputMap.has_action(controls.FORWARD):
		push_error("No control mapped for move forward. Please add an input map control. Disabling movement.")
		immobile = true
	if !InputMap.has_action(controls.BACKWARD):
		push_error("No control mapped for move backward. Please add an input map control. Disabling movement.")
		immobile = true
	if !InputMap.has_action(controls.PAUSE):
		push_error("No control mapped for pause. Please add an input map control. Disabling pausing.")
		pausing_enabled = false
	if !InputMap.has_action(controls.CROUCH):
		push_error("No control mapped for crouch. Please add an input map control. Disabling crouching.")
		crouch_enabled = false
	if !InputMap.has_action(controls.SPRINT):
		push_error("No control mapped for sprint. Please add an input map control. Disabling sprinting.")
		sprint_enabled = false

#endregion

#region State Handling

func _handle_state(moving : bool) -> void:
	if sprint_enabled:
		if sprint_mode == 0:
			if Input.is_action_pressed(controls.SPRINT) and state != "crouching":
				if moving:
					if state != "sprinting":
						_enter_sprint_state()
				else:
					if state == "sprinting":
						_enter_normal_state()
			elif state == "sprinting":
				_enter_normal_state()
		elif sprint_mode == 1:
			if moving:
				# If the player is holding sprint before moving, handle that scenario
				if Input.is_action_pressed(controls.SPRINT) and state == "normal":
					_enter_sprint_state()
				if Input.is_action_just_pressed(controls.SPRINT):
					match state:
						"normal":
							_enter_sprint_state()
						"sprinting":
							_enter_normal_state()
			elif state == "sprinting":
				_enter_normal_state()

	if crouch_enabled:
		if crouch_mode == 0:
			if Input.is_action_pressed(controls.CROUCH) and state != "sprinting":
				if state != "crouching":
					_enter_crouch_state()
			elif state == "crouching" and !$CrouchCeilingDetection.is_colliding():
				_enter_normal_state()
		elif crouch_mode == 1:
			if Input.is_action_just_pressed(controls.CROUCH):
				match state:
					"normal":
						_enter_crouch_state()
					"crouching":
						if !$CrouchCeilingDetection.is_colliding():
							_enter_normal_state()


# Any enter state function should only be called once when you want to enter that state, not every frame.
func _enter_normal_state() -> void:
	#print("entering normal state")
	var prev_state = state
	if prev_state == "crouching":
		CROUCH_ANIMATION.play_backwards("crouch")
	state = "normal"
	speed = base_speed

func _enter_crouch_state() -> void:
	#print("entering crouch state")
	state = "crouching"
	speed = crouch_speed
	CROUCH_ANIMATION.play("crouch")

func _enter_sprint_state() -> void:
	#print("entering sprint state")
	var prev_state = state
	if prev_state == "crouching":
		CROUCH_ANIMATION.play_backwards("crouch")
	state = "sprinting"
	speed = sprint_speed

#endregion

#region Animation Handling

func _initialize_animations() -> void:
	# Reset the camera position
	# If you want to change the default head height, change these animations.
	HEADBOB_ANIMATION.play("RESET")
	JUMP_ANIMATION.play("RESET")
	CROUCH_ANIMATION.play("RESET")

func _play_headbob_animation(moving : bool) -> void:
	if moving and is_on_floor():
		var use_headbob_animation : String
		match state:
			"normal","crouching":
				use_headbob_animation = "walk"
			"sprinting":
				use_headbob_animation = "sprint"

		var was_playing : bool = false
		if HEADBOB_ANIMATION.current_animation == use_headbob_animation:
			was_playing = true

		HEADBOB_ANIMATION.play(use_headbob_animation, 0.25)
		HEADBOB_ANIMATION.speed_scale = (current_speed / base_speed) * 1.75
		if !was_playing:
			HEADBOB_ANIMATION.seek(float(randi() % 2)) # Randomize the initial headbob direction
			# Let me explain that piece of code because it looks like it does the opposite of what it actually does.
			# The headbob animation has two starting positions. One is at 0 and the other is at 1.
			# randi() % 2 returns either 0 or 1, and so the animation randomly starts at one of the starting positions.
			# This code is extremely performant but it makes no sense.

	else:
		if HEADBOB_ANIMATION.current_animation == "sprint" or HEADBOB_ANIMATION.current_animation == "walk":
			HEADBOB_ANIMATION.speed_scale = 1
			HEADBOB_ANIMATION.play("RESET", 1)

func _play_jump_animation() -> void:
	if !was_on_floor and is_on_floor(): # The player just landed
		var facing_direction : Vector3 = CAMERA.get_global_transform().basis.x
		var facing_direction_2D : Vector2 = Vector2(facing_direction.x, facing_direction.z).normalized()
		var velocity_2D : Vector2 = Vector2(velocity.x, velocity.z).normalized()

		# Compares velocity direction against the camera direction (via dot product) to determine which landing animation to play.
		var side_landed : int = round(velocity_2D.dot(facing_direction_2D))

		if side_landed > 0:
			JUMP_ANIMATION.play("land_right", 0.25)
		elif side_landed < 0:
			JUMP_ANIMATION.play("land_left", 0.25)
		else:
			JUMP_ANIMATION.play("land_center", 0.25)

#endregion

#region Debug Menu

func _update_debug_menu_per_frame() -> void:
	if !$UserInterface/DebugPanel.visible: return

	$UserInterface/DebugPanel.add_property("FPS", Performance.get_monitor(Performance.TIME_FPS), 0)
	var status : String = state
	if !is_on_floor():
		status += " in the air"
	$UserInterface/DebugPanel.add_property("State", status, 4)


func _update_debug_menu_per_tick() -> void:
	if !$UserInterface/DebugPanel.visible: return

	# Big thanks to github.com/LorenzoAncora for the concept of the improved debug values
	$UserInterface/DebugPanel.add_property("Speed", snappedf(current_speed, 0.001), 1)
	$UserInterface/DebugPanel.add_property("Target speed", speed, 2)
	var cv : Vector3 = get_real_velocity()
	var vd : Array[float] = [
		snappedf(cv.x, 0.001),
		snappedf(cv.y, 0.001),
		snappedf(cv.z, 0.001)
	]
	var readable_velocity : String = "X: " + str(vd[0]) + " Y: " + str(vd[1]) + " Z: " + str(vd[2])
	$UserInterface/DebugPanel.add_property("Velocity", readable_velocity, 3)


func _unhandled_input(event : InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if web_mouse_workaround:
			mouse_input = event.screen_relative # Only the latest event, see web_mouse_workaround
		else:
			mouse_input += event.screen_relative # Several events can arrive before the next camera rotation
	# Toggle debug menu
	elif event is InputEventKey:
		if event.is_released():
			# Where we're going, we don't need InputMap
			if event.keycode == 4194338: # F7
				$UserInterface/DebugPanel.visible = !$UserInterface/DebugPanel.visible

#endregion

#region Misc Functions

func change_reticle(reticle) -> void: # Yup, this function is kinda strange
	if RETICLE:
		RETICLE.queue_free()

	RETICLE = load(reticle).instantiate()
	RETICLE.character = self
	$UserInterface.add_child(RETICLE)


func _update_camera_fov() -> void:
	# Moves 30% of the way to the target FOV every 1/60 s, at any FPS (this runs in _process)
	var weight : float = 1.0 - pow(0.7, get_process_delta_time() * 60.0)
	if state == "sprinting":
		CAMERA.fov = lerp(CAMERA.fov, 85.0, weight)
	else:
		CAMERA.fov = lerp(CAMERA.fov, 75.0, weight)

func _handle_pausing() -> void:
	if Input.is_action_just_pressed(controls.PAUSE):
		# You may want another node to handle pausing, because this player may get paused too.
		match Input.mouse_mode:
			Input.MOUSE_MODE_CAPTURED:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
				#get_tree().paused = false
			Input.MOUSE_MODE_VISIBLE:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
				#get_tree().paused = false

#endregion
