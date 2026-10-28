class_name Meeple extends Node3D

@onready var csg_cylinder_3d = $CSGCylinder3D

enum MEEPLETYPE {
	BANDIT,
	FARMER,
	KNIGHT,
	PRIEST
}

static var colored_materials : Dictionary[Color, StandardMaterial3D] = {}

func configure(color : Color, index : int, type : MEEPLETYPE):
	if not colored_materials.has(color):
		var newmat : StandardMaterial3D
		newmat = csg_cylinder_3d.material.duplicate()
		newmat.albedo_color = color
		colored_materials.set(color, newmat)
	csg_cylinder_3d.material = colored_materials.get(color)
