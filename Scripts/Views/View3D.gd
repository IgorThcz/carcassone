class_name View3D extends View

const RAY_LENGTH: float = 1000.0

const meeple_packed_scene   : PackedScene = preload("uid://dedly43amu28t")
const clickbox_packed_scene : PackedScene = preload("uid://b2ydf2f02si3p")

@onready var boxes    : Node3D    = $boxes
@onready var mouseray : RayCast3D = $mouseray
@onready var camera   : Camera3D  = $camera.get_camera_node()

"trocar por uma forma melhor depois"
@onready var meplacer : Control   = $VBoxContainer
var last_valids : Array[int] = []


var cards   : Dictionary[Vector2i, AutoSkin] = {}
var meeples : Dictionary[AutoSkin, Node3D]   = {}

var valid_boxes  : Array[ClickBox3D] = []
var current_card : CardStructure
var current_skin : AutoSkin

var skin_pos_tween : Tween
var last_tagt_pos  : Vector3 = Vector3.ZERO # nunca pode ser alvo válido

var skin_rot_tween : Tween
var last_tagt_rot  : float = 45 # (degrees) nunca pode ser válido

var current_click_box : ClickBox3D
var hud : GameHUD

var last_placed_skin : AutoSkin
var last_placed_card : CardStructure

"------------------------------ READY / PROCESS --------------------------------"

func _process(_delta: float) -> void:
	_calculate_ray()

func _ready():
	IM.mouse_button_event.connect(_handle_mouse_button_input)

"------------------------------ INPUT HANDLING ---------------------------------"

func _handle_mouse_button_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		# CLIQUE ESQUERDO -> CLIQUE NA CLICK_BOX
		if event.button_index == MOUSE_BUTTON_LEFT:
			_select_click_box()
		# CLIQUE DIREITO -> ROTAÇÃO DA CARTA
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_rotate_placing_card()

"----------------------------- CAIXAS DE CLIQUE --------------------------------"

func _calculate_ray():
	# obtém origem e direção do raio para o mouse na tela
	var mouse_pos : Vector2 = get_viewport().get_mouse_position()
	var ray_origin : Vector3 = camera.project_ray_origin(mouse_pos)
	var ray_normal : Vector3 = camera.project_ray_normal(mouse_pos)
	# configura o raycast
	var global_target : Vector3 = ray_origin + (ray_normal * RAY_LENGTH)
	mouseray.global_position = ray_origin
	mouseray.target_position = mouseray.to_local(global_target)
	# obriga a engine de física a atualizar o raio AGORA
	mouseray.force_raycast_update()
	_update_current_click_box()

func _update_current_click_box() -> void:
	if mouseray.is_colliding():
		var collider = mouseray.get_collider()
		# se o colisor é válido, define como selecionado
		if boxes.get_children().has(collider):
			if not collider.clickable: return
			if current_click_box: current_click_box.set_uncurrent()
			current_click_box = collider
			current_click_box.set_current()
			if current_skin:
				_tween_skin_to_global_position(current_click_box.global_position)

func _select_click_box() -> void:
	# retorna se nao estiver posicionando carta
	if state != STATE.PLACING_CARD: return
	if !current_click_box: return
	if current_click_box.rotation_is_valid(current_card.rotation):
		# obtém posição e rotação
		var grid_pos : Vector2i = current_click_box.vgrid_position
		var rot : CardStructure.CARDROTATION = current_card.rotation
		# esconde todas as caixas de clique
		boxes.hide()
		tile_placement_requested.emit(grid_pos, rot)

func _update_valid_boxes_for_click():
	for box in valid_boxes:
		if box.rotation_is_valid(current_card.rotation):
			box.set_clickable()
		else: box.set_unclickable()

"-------------------------- EXIBIÇÃO DA CARTA ATUAL ----------------------------"

func _tween_skin_to_global_position(pos : Vector3) -> void:
	if last_tagt_pos != pos:
		if skin_pos_tween: skin_pos_tween.kill()
		skin_pos_tween = get_tree().create_tween()
		skin_pos_tween.tween_property(current_skin, "global_position", pos, 0.1)

func _tween_skin_to_rotation(rot : float) -> void:
	if last_tagt_rot != rot:
		print("STARTET ROT TWEEN")
		if skin_rot_tween: skin_rot_tween.kill()
		skin_rot_tween = get_tree().create_tween()
		skin_rot_tween.tween_property(current_skin, "rotation_degrees:y", rot, 0.2)

func _rotate_placing_card() -> void:
	# apenas prossegue se estiver posicionando carta
	if state != STATE.PLACING_CARD: return
	# rotação da estrutura
	var next_rot : CardStructure.CARDROTATION
	next_rot = (int(current_card.rotation) + 1) % 4 as CardStructure.CARDROTATION
	var tgt_deg : float = CardStructure.rotation_to_degrees(next_rot)
	current_card.rotation = next_rot # rotação na estrutura
	_tween_skin_to_rotation(tgt_deg) # rotação visual
	_update_valid_boxes_for_click()

"---------------------------- RECEBE AS CHAMADAS -------------------------------"

func add_card(
	pos: Vector2i, id : int, rot : CardStructure.CARDROTATION
) -> void:
	if cards.has(pos):
		return
	var card_skin : AutoSkin = Catalogue.get_skin(id)
	add_child(card_skin)
	card_skin.global_position = Vector3(
		pos.x * AutoSkin.SIDE_LENGTH, 0.0, pos.y * AutoSkin.SIDE_LENGTH
	)
	card_skin.rotation_from_structure(rot)
	cards.set(pos, card_skin)
	# atualiza o eatado
	state = STATE.WAITING
	if current_skin: current_skin.hide()

func add_meeple(card_pos: Vector2i, meeple_index : int) -> void:
	var card_skin = cards.get(card_pos)
	if not card_skin or not meeple_packed_scene:
		return
	# adiciona o meeple visual
	card_skin.add_meeple_at_index(meeple_index)
	# se estava posicionando esse meeple, sai do modo
	if state == STATE.EXPECTING_ANSWER_MEEPLE:
		meplacer.hide()
		state = STATE.WAITING
	MO.sucess("Meeple placed at index "+str(meeple_index))

"NÃO REVISADO, ESPERE NÃO FUNCIONAR"
func remove_meeple(card_pos: Vector2i) -> void:
	var card_skin = cards.get(card_pos)
	if card_skin and meeples.has(card_skin):
		var meeple_node = meeples[card_skin]
		meeple_node.queue_free()
		meeples.erase(card_skin)

"-------------------- MODE SWITCH ----------------------"

func go_place_card_mode(
	card_id : int,
	vadjacents: Dictionary[Vector2i, Array]
) -> void:
	MO.sucess("starting placement mode for current player")
	# se o vadjacents vem vazio, significa que a carta deve ser recolocada
	# novamente, então o estado das click_boxes já está definido
	if skin_pos_tween: skin_pos_tween.kill()
	if skin_rot_tween: skin_rot_tween.kill()
	var card : CardStructure = Catalogue.get_structure(card_id)
	if not vadjacents.is_empty():
		# garante toda carta nova em rotação UP
		current_card = card
		current_card.set_rotation(CardStructure.CARDROTATION.UP)
		# configura a carta visual
		if current_skin: current_skin.queue_free()
		var auto_skin : AutoSkin = AutoSkin.new()
		auto_skin.build(card_id)
		add_child(auto_skin)
		current_skin = auto_skin
		# configura as áreas de clique
		valid_boxes = [] # reseta lista de caixas sendo usadas
		var counter : int = 0
		var max_c   : int = boxes.get_child_count() # erro aqui
		var click_boxes : Array = boxes.get_children()
		for key in vadjacents.keys():
			var pos : Vector2i = key
			var valids : Array[CardStructure.CARDROTATION] = []
			valids.assign(vadjacents.get(key, []))
			var click_box : ClickBox3D
			print(counter," ", max_c)
			if counter < max_c: # get existing click box
				click_box = click_boxes.get(counter)
			else: # or create new
				click_box = clickbox_packed_scene.instantiate()
				boxes.add_child(click_box)
			# adiciona a caixa na lista de caixas sendo usadas
			valid_boxes.append(click_box)
			# configure_click_boxes
			click_box.show()
			click_box.set_valid_rotations(valids)
			click_box.set_vec2_position(pos)
			counter += 1
		# hide_unecessary
		if counter < max_c:
			for i in range(counter, max_c):
				click_boxes.get(counter + i).hide()
		# define o estado quanto à rotação
		_update_valid_boxes_for_click()
		# define o estado
	# configura o estado
	state = STATE.PLACING_CARD
	current_skin.show()

func _go_to_wait_card_placement_answer_mode():
	state = STATE.EXPECTING_ANSWER_CARD
	current_skin.hide()

"NÃO REVISADO, ESPERE NÃO FUNCIONAR"
func go_place_meeple_mode(valids: Array[int]) -> void:
	last_valids = valids
	meplacer.show()
	state = STATE.PLACING_MEEPLE

"NÃO REVISADO, ESPERE NÃO FUNCIONAR"
func exit_all_modes() -> void:
	return

"---------------------- meeple Placement -----------------------"

func _on_button_pressed():
	var index : int = int($VBoxContainer/SpinBox.value)
	if last_valids.has(index) and state == STATE.PLACING_MEEPLE:
		meeple_placement_requested.emit(index-1)
		state = STATE.EXPECTING_ANSWER_MEEPLE
		MO.sucess("meeple asked at index " + str(index-1))
