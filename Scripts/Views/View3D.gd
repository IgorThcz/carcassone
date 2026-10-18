class_name View3D extends View

const RAY_LENGTH: float = 1000.0

@export var meeple_packed_scene : PackedScene
@export var clibox_packed_scene : PackedScene

@onready var mouseray : RayCast3D = $mouseray
@onready var camera   : Node3D    = $camera.get_camera_node()

var cards   : Dictionary[Vector2i, AutoSkin] = {}
var meeples : Dictionary[AutoSkin, Node3D] = {}
var click_boxes : Array[Node3D] = []

func _process(delta: float) -> void:
	var mouse_pos := get_viewport().get_mouse_position()
	
	# 1. Pega a matemática da câmera
	var ray_origin : Vector3 = camera.project_ray_origin(mouse_pos)
	var ray_normal : Vector3 = camera.project_ray_normal(mouse_pos)
	
	# 2. Move a origem do nó RayCast3D para a lente da câmera
	mouseray.global_position = ray_origin
	
	# 3. Define para onde ele aponta. 
	var global_target := ray_origin + (ray_normal * RAY_LENGTH)
	mouseray.target_position = mouseray.to_local(global_target)
	
	# 4. Força a engine física a calcular a colisão IMEDIATAMENTE.
	mouseray.force_raycast_update()

var _pending_rotation: CardStructure.CARDROTATION = CardStructure.CARDROTATION.UP

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if mouseray.is_colliding():
				var collider = mouseray.get_collider()
				
				if click_boxes.has(collider):
					click_box_selected(collider)
					
				elif collider.has_meta("meeple_index"):
					var c_pos: Vector2i = collider.get_meta("card_pos")
					var m_idx: int = collider.get_meta("meeple_index")
					meeple_placement_requested.emit(c_pos, m_idx)
					
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_rotate_pending()

func _rotate_pending() -> void:
	# só faz sentido girar se estivermos de fato no modo de colocação de carta
	if click_boxes.is_empty():
		return
	var next_val: int = (int(_pending_rotation) + 1) % 4
	_pending_rotation = next_val as CardStructure.CARDROTATION
	_update_preview_rotation()

func _update_preview_rotation() -> void:
	# opcional: se as click_boxes tiverem algum indicador visual de orientação
	# (ex: uma seta), atualiza aqui. Deixe vazio se não houver.
	for box in click_boxes:
		if box.has_method("set_preview_rotation"):
			box.set_preview_rotation(_pending_rotation)

"------------------- RECEBE AS CHAMADAS ---------------------"

func add_card(pos: Vector2i, id : int, rot : CardStructure.CARDROTATION) -> void:
	if cards.has(pos):
		return
		
	var card_skin : AutoSkin = Catalogue.get_skin(id)
	add_child(card_skin)
	card_skin.global_position = Vector3(pos.x * 2.0, 0.0, pos.y * 2.0)
	card_skin.rotation_from_structure(rot)
	
	cards.set(pos, card_skin)

func add_meeple(card_pos: Vector2i, meeple_index : int) -> void:
	var card_skin = cards.get(card_pos)
	if not card_skin or not meeple_packed_scene:
		return
		
	# Instancia o meeple visual
	var meeple_node = meeple_packed_scene.instantiate()
	card_skin.add_child(meeple_node)
	
	# Obtém a posição 3D local do slot no AutoSkin (caso exista método/nó de marcação)
	if card_skin.has_method("get_slot_local_position"):
		meeple_node.position = card_skin.get_slot_local_position(meeple_index)
	else:
		var slot_node = card_skin.get_node_or_null("Slots/Slot_" + str(meeple_index))
		if slot_node:
			meeple_node.position = slot_node.position
			
	meeples[card_skin] = meeple_node

func remove_meeple(card_pos: Vector2i) -> void:
	var card_skin = cards.get(card_pos)
	if card_skin and meeples.has(card_skin):
		var meeple_node = meeples[card_skin]
		meeple_node.queue_free()
		meeples.erase(card_skin)

func place_mode(vadjacents: Array[Vector2i]) -> void:
	_pending_rotation = CardStructure.CARDROTATION.UP # reseta pra cada carta nova
	
	for box in click_boxes:
		box.queue_free()
	click_boxes.clear()
	
	if not clibox_packed_scene:
		return
		
	for pos in vadjacents:
		var box = clibox_packed_scene.instantiate()
		add_child(box)
		box.global_position = Vector3(pos.x * 2.0, 0.0, pos.y * 2.0)
		box.set_meta("grid_pos", pos)
		click_boxes.append(box)

"-------------------- GERA CHAMADA (CLIQUE) ----------------------"

func click_box_selected(box: Node3D) -> void:
	var grid_pos: Vector2i = box.get_meta("grid_pos")
	var rot := _pending_rotation
	
	for b in click_boxes:
		b.queue_free()
	click_boxes.clear()
	
	tile_placement_requested.emit(grid_pos, rot)
