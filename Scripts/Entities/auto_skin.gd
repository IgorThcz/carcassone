class_name AutoSkin extends Node3D

const array_meshes_path : String = "res://Assets/ModularPieces/"

# type -> ArrayMesh
const floors : Dictionary[String, ArrayMesh] = {
	"corner_city"     : preload("uid://k672hpr1314p"),
	"side_city"       : preload("uid://qhd0cqln6m1g"),
	"side_long_road"  : preload("uid://ivgc30a44cwc"),
	"side_short_road" : preload("uid://b12j4dte48xym"),
	"center_city"     : preload("uid://dpp4tg8n3xbuv"),
	"center_road"     : preload("uid://dyriobednrwye") 
}

func build(num : int):
	print("skin builder requested structure")
	var structure : CardStructure = Catalogue.get_structure(num)
	print(">>> ", structure)
	for i in range(4):
		for j in range(3):
			var index : int = i * 3 + j
			var part  : CardPart = structure.get_part(index)
			
			# modifications
			var rotation_deg : float
			var scale_x      : float
			
			#region -------------------- CORNERS --------------------
			# if is corner
			if j != 1:
				rotation_deg = -90 * i
				# if is city
				if part is City:
					# first or second corner on side
					var offset : int = 1
					scale_x = -1
					if j == 0:
						offset = -1
						scale_x = 1
					# only one floor possible (city)
					add_floor("corner_city", rotation_deg, scale_x)
					# if other corner is connected city
					if structure.get_part(index + offset, true).inner_connects_to(part):
						# extra point or not
						if part.extra_points:
							# add child
							add_voxels("uid://d4h0vg22q1w1m", rotation_deg, scale_x)
						else:
							# add child
							add_voxels("uid://dss3yhikuovc2", rotation_deg, scale_x)
					# if corner is not connected city
					else:
						# extra point or not
						if part.extra_points:
							# add child
							add_voxels("uid://cmkr03vi6tqtv", rotation_deg, scale_x)
						else:
							# add child
							add_voxels("uid://dt3g8ucgbkhk0", rotation_deg, scale_x)
			#endregion ----------------------------------------------
			
			#region --------------------- SIDES ---------------------
			# if is side
			else:
				rotation_deg = -90 * i
				scale_x = 1
				# if is city
				if part is City:
					# only one city floor variation
					add_floor("side_city", rotation_deg, scale_x)
					# if center is city, place without wall
					if structure.get_part(-1) is City:
						# extra point or not
						if part.extra_points:
							# add child
							print("SKINLOG: NO WALL, EXTRA POINT")
							add_voxels("uid://570dh7pu8e0q", rotation_deg, scale_x)
						else:
							# add child
							print("SKINLOG: NO WALL, NO EXTRA POINT")
							add_voxels("uid://didmvlps2wk64", rotation_deg, scale_x)
					# else, place with wall
					else:
						# extra point or not
						if part.extra_points:
							# add child
							print("SKINLOG: WALL, EXTRA POINT")
							add_voxels("uid://kky0fhlc6ge2", rotation_deg, scale_x)
						else:
							# add child
							print("SKINLOG: WALL, NO EXTRA POINT")
							add_voxels("uid://ccjb5m6vx68y1", rotation_deg, scale_x)
				# if is road
				elif part is Road:
					# if middle is city, use short road
					if structure.get_part(-1) is City:
						add_floor("side_short_road", rotation_deg, 1)
					# else, use long road
					else:
						add_floor("side_long_road", rotation_deg, 1)
			#endregion ----------------------------------------------
			
	#region -------------------- MIDDLE ---------------------
	var part : CardPart = structure.get_part(-1)
	# no middle means a crossroad (not a road)
	if not part:
		add_floor("center_road", 0, 1)
		return
	var type : CardPart.TYPES = part.get_type()
	if type == CardPart.TYPES.CITY:
		# floor is always center city
		add_floor("center_city", 0, 1)
		# get all adjacent CardParts that are not cities
		var not_city_adjacencies : Array[int] = []
		for k in range(4):
			var index : int = 1 + k * 3 # middle sides indexes
			var side  : CardPart = structure.get_part(index)
			var stype : CardPart.TYPES = side.get_type()
			if stype != CardPart.TYPES.CITY:
				not_city_adjacencies.append(k)
		# if there is only one, place center city with one wall
		if not_city_adjacencies.size() == 1:
			var k : int = not_city_adjacencies[0]
			var rot : float = k * -90
			if part.extra_points:
				add_voxels("uid://b5pis5ova1axo", rot, 1)
			else:
				add_voxels("uid://bm2611k7yrhyg", rot, 1)
		# if there is two, place with two
		elif not_city_adjacencies.size() == 2:
			var k : int = not_city_adjacencies[0]
			var rot : float = k * -90
			if part.extra_points:
				add_voxels("uid://dfj6wsriqnnle", rot, 1)
			else:
				add_voxels("uid://k8h8c587h2fr", rot, 1)
		# if there is none, place with no walls
		else:
			if part.extra_points:
				add_voxels("uid://djp7unj2haf3r", 0, 1)
			else:
				add_voxels("uid://c7hnrqpyjo8by", 0, 1)
	elif type == CardPart.TYPES.MONASTERY:
		# monastery is always the same
		add_floor("center_road", 0, 1)
		add_voxels("uid://i471jo0546ho", 0, 1)
	elif type == CardPart.TYPES.ROAD:
		# center road has no variations
		add_floor("center_road", 0, 1)
	#endregion ----------------------------------------------

# add voxels child and transform
func add_voxels(uid : String, rotation_deg : float, scale_x : float):
	var obj : MeshInstance3D = MeshInstance3D.new()
	obj.mesh = load(uid)
	obj.rotation_degrees.y = rotation_deg
	obj.scale.x = scale_x
	add_child(obj)

# add floor child and transform
func add_floor(floor_texture : String, rotation_deg : float, scale_x : float):
	var tex : MeshInstance3D = MeshInstance3D.new()
	tex.mesh = floors.get(floor_texture)
	tex.rotation_degrees.y = rotation_deg
	tex.scale.x = scale_x
	add_child(tex)

func rotation_from_structure(rotation : CardStructure.CARDROTATION):
	rotation_degrees.y = 90 * rotation
