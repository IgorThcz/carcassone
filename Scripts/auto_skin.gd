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
	var structure : CardStruture = Catalogue.get_structure(num)
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
				if part.type == CardPart.TYPES.CITY:
					# first or second corner on side
					var offset : int = 1
					scale_x = -1
					if j == 0:
						offset = -1
						scale_x = 1
					# only one floor possible (city)
					add_floor("corner_city", rotation_deg, scale_x)
					# if other corner is connected city
					if structure.get_part(index + offset, true).connects_to(part):
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
				if part.type == CardPart.TYPES.CITY:
					# only one city floor variation
					add_floor("side_city", rotation_deg, scale_x)
					# if center is city, place without wall
					if structure.get_part(-1).type == CardPart.TYPES.CITY:
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
				elif part.type == CardPart.TYPES.ROAD:
					# if middle is city, use short road
					if structure.get_part(-1).type == CardPart.TYPES.CITY:
						add_floor("side_short_road", rotation_deg, 1)
					# else, use long road
					else:
						add_floor("side_long_road", rotation_deg, 1)
			#endregion ----------------------------------------------
			
			#region -------------------- MIDDLE ---------------------
			# ignore now
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
