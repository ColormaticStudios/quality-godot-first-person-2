@tool
extends Node

# This module affects runtime nad 


#TODO: Add descriptions
@export_category("Controller Editor Module")
@export var head_y_rotation : float = 0:
	set(new_rotation):
		head_y_rotation = new_rotation
		HEAD.rotation.y = head_y_rotation
		update_configuration_warnings()

@export_group("Nodes")
@export var CHARACTER : CharacterBody3D
@export var head_path : String = "Head" # From this nodes parent node
#@export var CAMERA : Camera3D
#@export var HEADBOB_ANIMATION : AnimationPlayer
#@export var JUMP_ANIMATION : AnimationPlayer
#@export var CROUCH_ANIMATION : AnimationPlayer
#@export var COLLISION_MESH : CollisionShape3D

var HEAD


func _ready():
	HEAD = get_node("../" + head_path)
	if Engine.is_editor_hint():
		pass
	else:
		HEAD.rotation.y = head_y_rotation

func _process(delta):
	if Engine.is_editor_hint():
		pass

func _get_configuration_warnings():
	var warnings = []

	if head_y_rotation > 360:
		warnings.append("The head rotation is greater than 360")
	
	if head_y_rotation < 0:
		warnings.append("The head rotation is less than 0")

	# Returning an empty array gives no warnings
	return warnings
