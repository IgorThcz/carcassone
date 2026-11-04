class_name MeepleIndexInput extends Node3D

const blue_material   : StandardMaterial3D = preload("uid://dw2sfmecocxt2")
const yellow_material : StandardMaterial3D = preload("uid://b6okiw40h0xss")

@onready var button = $MarginContainer/Button
signal skip_placement

@onready var indexes : Dictionary[int, StaticBody3D] = {
	0  : $MeshInstance3D/corner7/StaticBody3D,
	1  : $MeshInstance3D/side3/StaticBody3D,
	2  : $MeshInstance3D/corner5/StaticBody3D,
	3  : $MeshInstance3D/corner6/StaticBody3D,
	4  : $MeshInstance3D/side2/StaticBody3D,
	5  : $MeshInstance3D/corner/StaticBody3D,
	6  : $MeshInstance3D/corner2/StaticBody3D,
	7  : $MeshInstance3D/side4/StaticBody3D,
	8  : $MeshInstance3D/corner4/StaticBody3D,
	9  : $MeshInstance3D/corner3/StaticBody3D,
	10 : $MeshInstance3D/side/StaticBody3D,
	11 : $MeshInstance3D/corner8/StaticBody3D,
	12 : $MeshInstance3D/center/StaticBody3D, # centro: index = 12
}

var valid_indexes : Array = []
var current_hover : StaticBody3D

func _ready() -> void:
	for key in indexes.keys():
		var body : StaticBody3D = indexes.get(key)
		if body: body.set_meta("index", key)

func configure_valid_indexes(valids : Array[int]) -> void:
	button.show()
	valid_indexes = valids
	for key in indexes.keys():
		var body : StaticBody3D = indexes.get(key)
		if valid_indexes.has(key):
			var mesh_inst : MeshInstance3D = body.get_parent()
			mesh_inst.show()
			mesh_inst.material_override = blue_material
			body.get_child(0).disabled = false
		else:
			body.get_parent().hide()
			body.get_child(0).disabled = true

func disable() -> void:
	button.hide()
	for body in indexes.values():
		body.get_parent().hide()
		body.get_child(0).disabled = true

func index_hovered(index : int):
	var body : StaticBody3D = indexes.get(index, null)
	if not body: return
	index_unhovered()
	body.get_parent().material_override = yellow_material
	current_hover = body

func index_unhovered():
	if current_hover:
		current_hover.get_parent().material_override = blue_material

func _on_button_pressed():
	skip_placement.emit()
