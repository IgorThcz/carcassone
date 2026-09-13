@tool extends Node

var json_path : String = "res://Resources/cards.json"

var skins   : Dictionary[int, Node3D] = {}
var models  : Dictionary = {}
var structs : Dictionary[int, CardStructure] = {}

func get_model(num : int):
	print("model returned:\n", models.get(str(num), []))
	return models.get(str(num), [])
	
func _ready() -> void:
	load_cards()

# parse json cards file to a dictionary variable
func load_cards() -> void:
	# locate, if can't then return
	if not FileAccess.file_exists(json_path):
		printerr("JSON file not fount at path: ", json_path)
		return
	# open, if can't then return
	var file = FileAccess.open(json_path, FileAccess.READ)
	if not file:
		printerr("It was not possoble to open JSON file at: ", json_path)
		return
	# parse json file
	var json_text = file.get_as_text()
	var json = JSON.new()
	var result = json.parse(json_text)
	# if an error ocurred, return
	if result != OK:
		printerr(
			"Error parsing json at line: ",
			json.get_error_line(),
			": ",
			json.get_error_message()
			)
		return
	# get json data as a dictionary, if can't then do not set at variable
	var data = json.get_data()
	if typeof(data) == TYPE_DICTIONARY:
		models = data
		print(models.size(), " card models loaded from JSON file")
	else:
		printerr("Parsed JSON file is not a dictionary")

# return cards structures under demand using cache for repeated requisitions
func get_structure(num : int) -> CardStructure:
	# if num is invalid, return
	if num < 1 or num > models.size():
		print("number invalid for structure")
		return null
	# if structure is already built, return it
	if structs.has(num):
		var dup = structs.get(num).duplicate() as CardStructure
		dup.build(get_model(num))
		print("structure duplicated and returned from cache")
		return dup
	# else, make struct, save and return
	var struct : CardStructure = CardStructure.new()
	struct.build(get_model(num))
	structs.set(num, struct)
	print("structure created and returned: ", struct)
	return struct

# return cards skins under demand using cache for repeated requisitions
func get_skin(num : int) -> Node3D:
	# if num is invalid, return
	if num < 1 or num > models.size():
		print("number invalid for skin")
		return null
	# if skin is already built, return it
	if skins.has(num):
		var dup : AutoSkin = skins.get(num).duplicate()
		dup.build(num)
		print("skin duplicated and returned from cache: ", dup)
		return dup
	# else, make skin, save and return
	var skin : Node3D = AutoSkin.new() # AutoSkin extends Node3D
	skin.build(num)
	skins.set(num, skin)
	print("skin created and returned")
	return skin
