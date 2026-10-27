class_name ClickBox3D extends StaticBody3D

const blue_material   : StandardMaterial3D = preload("uid://dw2sfmecocxt2")
const white_material  : StandardMaterial3D = preload("uid://c3meit541ygon")
const yellow_material : StandardMaterial3D = preload("uid://b6okiw40h0xss")

@onready var mesh_instance_3d   = $MeshInstance3D
@onready var collision_shape_3d = $CollisionShape3D

var vgrid_position  : Vector2i = Vector2i.ZERO
var valid_rotations : Array[CardStructure.CARDROTATION] = []

var clickable : bool = false

func set_current():
	mesh_instance_3d.material_override = yellow_material
func set_uncurrent():
	if clickable:
		mesh_instance_3d.material_override = blue_material
	else:
		mesh_instance_3d.material_override = white_material

func set_clickable():
	clickable = true
	mesh_instance_3d.material_override = blue_material

func set_unclickable():
	clickable = false
	mesh_instance_3d.material_override = white_material

func set_vec2_position(pos : Vector2i) -> void:
	var multpl : float = AutoSkin.SIDE_LENGTH
	vgrid_position = pos
	global_position = Vector3(pos.x * multpl, 0, pos.y * multpl)

func set_valid_rotations(valids : Array[CardStructure.CARDROTATION]) -> void:
	valid_rotations = valids

func rotation_is_valid(rot : CardStructure.CARDROTATION) -> bool:
	return valid_rotations.has(rot)
