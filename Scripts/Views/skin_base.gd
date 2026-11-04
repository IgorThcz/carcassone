class_name SkinBase extends Node3D

const MEEPLE_SCENE : PackedScene = preload("uid://dedly43amu28t")

var active_indexes : Array[int] = []

@onready var indexes : Dictionary[int, Marker3D] = {
	12 : $center,
	0  : $Marker3D11,
	1  : $Marker3D7,
	2  : $Marker3D9,
	3  : $Marker3D5,
	4  : $Marker3D,
	5  : $Marker3D3,
	6  : $Marker3D10,
	7  : $Marker3D8,
	8  : $Marker3D12,
	9  : $Marker3D4,
	10 : $Marker3D2,
	11 : $Marker3D6
}

func place_meeple_at(index : int, color : Color) -> void:
	if not indexes.has(index): return
	var marker : Marker3D = indexes.get(index, null)
	if not marker: return
	var meeple = MEEPLE_SCENE.instantiate()
	marker.add_child(meeple)
	meeple.configure(color)
	active_indexes.append(index)

func remove_all_meeples():
	hide()
	for index : int in active_indexes:
		remove_meeple_from(index)
	active_indexes.clear()

func remove_meeple_from(index : int) -> bool:
	if indexes.has(index): return false
	var marker : Marker3D = indexes.get(index, null)
	if not marker: return false
	if marker.get_child_count() == 0: return false
	marker.get_child(0).queue_free()
	return true
