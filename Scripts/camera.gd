extends Node3D

"------------------------------------------ VARIABLES ----------------------------------------------"

@onready var camera_pivot : Node3D   = $camera_pivot
@onready var camera       : Camera3D = $camera_pivot/Camera3D

var movement_vel : float = 1

@export var max_zoom  : float = 20
@export var min_zoom  : float = 0.5

var zoom_vel  : float = 1
var tgt_zoom : float = 10:
	set(value):
		tgt_zoom = clamp(value, min_zoom, max_zoom)

var camera_vel_x : float = 1
var camera_vel_y : float = 1
var conversion   : float = 0.01

var angle            : float = -45
var min_angle        : float = -90
var max_angle        : float = -5
var angle_conversion : float = 0.5

"------------------------------------------- CAMERA ------------------------------------------------"

func _physics_process(_delta):
	camera.position.z += (tgt_zoom - camera.position.z) / 2

func _input(event : InputEvent):
	if event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
			rotation(event)
		elif Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			movement(event)
	elif event is InputEventMouseButton and event.pressed:
		zoom(event)

func rotation(event : InputEvent):
	var delta = event.relative
	
	var rotat_vel_x = delta.x * camera_vel_x * conversion * -1
	camera_pivot.rotate_y(rotat_vel_x)
	
	var rotat_vel_y = delta.y * camera_vel_y * angle_conversion * -1
	angle += rotat_vel_y
	if angle > -20: angle = -20
	if angle < -90: angle = -90
	camera_pivot.rotation_degrees.x = angle

func movement(event : InputEvent):
	var delta = event.relative

	var forward = -camera_pivot.global_transform.basis.z
	var right = camera_pivot.global_transform.basis.x
	
	forward.y = 0
	forward = forward.normalized()
	right.y = 0
	right = right.normalized()
	
	var move_vector = (right * -delta.x + forward * delta.y)\
	* movement_vel * conversion * tgt_zoom / 4
	
	camera_pivot.global_translate(move_vector)

func zoom(event : InputEvent):
	if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			tgt_zoom -= zoom_vel
	elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		tgt_zoom += zoom_vel
		
	tgt_zoom = clamp(tgt_zoom, min_zoom, max_zoom)
