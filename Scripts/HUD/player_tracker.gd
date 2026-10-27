class_name PlayerTracker extends Panel

@onready var rtl_number_name : RichTextLabel = $MarginContainer/HBoxContainer/VBoxContainer/number_name
@onready var rtl_meeples     : RichTextLabel = $MarginContainer/HBoxContainer/VBoxContainer/meeples
@onready var rtl_points      : RichTextLabel = $MarginContainer/HBoxContainer/VBoxContainer/points
@onready var rect_portrait   : TextureRect   = $MarginContainer/HBoxContainer/TextureRect

var tween : Tween

var current : bool = false

var id      : String
var name_   : String
var color   : Color
var points  : int
var meeples : int

func set_data(
	id_      : String,
	name__   : String,
	color_   : Color,
	points_  : int,
	meeples_ : int
):
	# save info
	id      = id_
	name_   = name__
	color   = color_
	points  = points_
	meeples = meeples_
	# update appearence
	rtl_number_name.text = id + " | " + name_
	rtl_meeples    .text = str(meeples) + " / " + str(GameManager.active_config.meeple_limit)
	rtl_points     .text = str(points)
	rect_portrait.modulate = color


func get_id() -> String:
	return id

func set_current():
	if not current:
		current = true
		glow_in()

func set_uncurrent():
	if current:
		current = false
		glow_out()

func glow_in() -> void:
	if tween: tween.free()
	tween = get_tree().create_tween()
	tween.tween_property(self, "self_modulate", Color(1.0, 0.627, 0.0, 1.0), 0.5)

func glow_out() -> void:
	if tween: tween.free()
	tween = get_tree().create_tween()
	tween.tween_property(self, "self_modulate", Color.WHITE, 0.5)
