class_name View3D extends View

const RAY_LENGTH: float = 1000.0

const clickbox_packed_scene : PackedScene = preload("uid://b2ydf2f02si3p")

@onready var boxes    : Node3D    = $boxes
@onready var mouseray : RayCast3D = $mouseray
@onready var camera   : Camera3D  = $camera.get_camera_node()

# PARA TESTES (TEMPORARIO)
@onready var modetext = $VBoxContainer2/modetext

"trocar por uma forma melhor depois"
@onready var meplacer : Control   = $VBoxContainer

"------------------------------- MODOS ATIVOS ----------------------------------"
# um booleano por modo, independentes entre si.
# true  = o modo aceita input
# false = o modo não aceita input (inativo, ou já enviou e espera resposta)
var placing_card   : bool = false
var placing_meeple : bool = false

"---------------------------- DADOS DOS MODOS ----------------------------------"

# --- modo carta ---
var cards   : Dictionary[Vector2i, AutoSkin] = {}
var meeples : Dictionary[AutoSkin, Node3D]   = {}

var valid_boxes       : Array[ClickBox3D] = []
var current_click_box : ClickBox3D
var current_card      : CardStructure
var current_skin      : AutoSkin

var skin_pos_tween : Tween
var last_tagt_pos  : Vector3 = Vector3.INF # nunca é um alvo válido

var skin_rot_tween : Tween
var last_tagt_rot  : float = INF           # nunca é um alvo válido

# --- modo meeple ---
var last_valids : Array[int] = []          # índices 0-based, como a Logic envia

"------------------------------ READY / PROCESS --------------------------------"

func _process(_delta: float) -> void:
	if placing_card:
		_calculate_ray()

func _ready() -> void:
	IM.mouse_button_event.connect(_handle_mouse_button_input)
	exit_all_modes()

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

func _calculate_ray() -> void:
	# obtém origem e direção do raio para o mouse na tela
	var mouse_pos  : Vector2 = get_viewport().get_mouse_position()
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
	if not mouseray.is_colliding():
		return
	var collider = mouseray.get_collider()
	# só aceita caixas deste grupo, visíveis e clicáveis
	if not (collider is ClickBox3D) or collider.get_parent() != boxes:
		return
	if not collider.is_visible_in_tree() or not collider.clickable:
		return
	if current_click_box and current_click_box != collider:
		current_click_box.set_uncurrent()
	current_click_box = collider
	current_click_box.set_current()
	if current_skin:
		_tween_skin_to_global_position(current_click_box.global_position)

func _select_click_box() -> void:
	if not placing_card: return
	if not current_click_box: return
	if not current_click_box.rotation_is_valid(current_card.rotation): return
	# obtém posição e rotação
	var grid_pos : Vector2i = current_click_box.vgrid_position
	var rot : CardStructure.CARDROTATION = current_card.rotation
	# o modo para de aceitar input até a resposta (a skin de preview fica)
	placing_card = false
	boxes.hide()
	tile_placement_requested.emit(grid_pos, rot)

func _update_valid_boxes_for_click() -> void:
	for box in valid_boxes:
		if box.rotation_is_valid(current_card.rotation):
			box.set_clickable()
		else:
			box.set_unclickable()

"-------------------------- EXIBIÇÃO DA CARTA ATUAL ----------------------------"

func _tween_skin_to_global_position(pos : Vector3) -> void:
	if last_tagt_pos == pos: return
	last_tagt_pos = pos
	if skin_pos_tween: skin_pos_tween.kill()
	skin_pos_tween = get_tree().create_tween()
	skin_pos_tween.tween_property(current_skin, "global_position", pos, 0.1)

func _tween_skin_to_rotation(rot : float) -> void:
	if last_tagt_rot == rot: return
	last_tagt_rot = rot
	# o Godot devolve o ângulo normalizado (270 vira -90), então escolhe o
	# equivalente do alvo mais próximo do ângulo atual (ex.: 270 -> 0 vira -90 -> 0)
	var current : float = current_skin.rotation_degrees.y
	var target  : float = current + wrapf(rot - current, -180.0, 180.0)
	if skin_rot_tween: skin_rot_tween.kill()
	skin_rot_tween = get_tree().create_tween()
	skin_rot_tween.tween_property(current_skin, "rotation_degrees:y", target, 0.2)

func _rotate_placing_card() -> void:
	if not placing_card: return
	var next_rot : CardStructure.CARDROTATION
	next_rot = (int(current_card.rotation) + 1) % 4 as CardStructure.CARDROTATION
	current_card.rotation = next_rot # rotação na estrutura
	_tween_skin_to_rotation(CardStructure.rotation_to_degrees(next_rot)) # visual
	_update_valid_boxes_for_click()

"---------------------------- RECEBE AS CHAMADAS -------------------------------"
# NÃO AFETAM OS MODOS

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

func add_meeple(card_pos: Vector2i, meeple_index : int) -> void:
	var card_skin : AutoSkin = cards.get(card_pos)
	if not card_skin:
		return
	card_skin.add_meeple_at_index(meeple_index)
	MO.success("Meeple placed at index " + str(meeple_index))

"NÃO REVISADO, ESPERE NÃO FUNCIONAR"
func remove_meeple(card_pos: Vector2i) -> void:
	var card_skin = cards.get(card_pos)
	if card_skin and meeples.has(card_skin):
		var meeple_node = meeples[card_skin]
		meeple_node.queue_free()
		meeples.erase(card_skin)

"------------------------------ ENTRAR EM MODOS --------------------------------"
# cada método liga só o seu modo; não mexe nos outros

# vadjacents vazio = repetir o posicionamento (reaproveita skin e caixas)
func go_place_card_mode(
	card_id : int,
	vadjacents: Dictionary[Vector2i, Array]
) -> void:
	if skin_pos_tween: skin_pos_tween.kill()
	if skin_rot_tween: skin_rot_tween.kill()
	# retry sem nada para reaproveitar: não há como entrar no modo
	if vadjacents.is_empty() and (current_skin == null or current_card == null):
		push_warning("go_place_card_mode: retry sem carta atual")
		return
	if not vadjacents.is_empty():
		_setup_new_card(card_id, vadjacents)
	# retry: as caixas já estão configuradas, só reexibe
	boxes.show()
	current_skin.show()
	placing_card = true

func go_place_meeple_mode(valids: Array[int]) -> void:
	last_valids = valids
	meplacer.show()
	placing_meeple = true

"------------------------------ SAIR DOS MODOS ---------------------------------"

func exit_all_modes() -> void:
	# modo carta
	placing_card = false
	boxes.hide()
	if skin_pos_tween: skin_pos_tween.kill()
	if skin_rot_tween: skin_rot_tween.kill()
	if current_click_box:
		current_click_box.set_uncurrent()
		current_click_box = null
	if current_skin:
		current_skin.hide()
	# modo meeple
	placing_meeple = false
	meplacer.hide()

"------------------------------- AUXILIARES ------------------------------------"

func _setup_new_card(
	card_id : int,
	vadjacents: Dictionary[Vector2i, Array]
) -> void:
	# carta nova sempre em UP
	# (Catalogue.get_structure precisa devolver uma cópia)
	current_card = Catalogue.get_structure(card_id)
	current_card.set_rotation(CardStructure.CARDROTATION.UP)
	# reseta o estado visual de rotação/posição
	last_tagt_pos = Vector3.INF
	last_tagt_rot = INF
	# skin de preview
	if current_skin: current_skin.queue_free()
	var auto_skin : AutoSkin = AutoSkin.new()
	auto_skin.build(card_id)
	add_child(auto_skin)
	current_skin = auto_skin
	auto_skin.rotation_degrees.y = CardStructure.rotation_to_degrees(
		CardStructure.CARDROTATION.UP
	)
	# turno novo: esquece a caixa do turno anterior
	if current_click_box:
		current_click_box.set_uncurrent()
		current_click_box = null
	# áreas de clique (reaproveita as existentes, cria se faltar)
	valid_boxes = []
	var click_boxes : Array = boxes.get_children()
	var existing    : int   = click_boxes.size()
	var counter     : int   = 0
	for key in vadjacents.keys():
		var pos    : Vector2i = key
		var valids : Array[CardStructure.CARDROTATION] = []
		valids.assign(vadjacents.get(key, []))
		var click_box : ClickBox3D
		if counter < existing:
			click_box = click_boxes[counter]
		else:
			click_box = clickbox_packed_scene.instantiate()
			boxes.add_child(click_box)
		valid_boxes.append(click_box)
		click_box.show()
		click_box.set_valid_rotations(valids)
		click_box.set_vec2_position(pos)
		counter += 1
	# esconde as sobrantes
	for i in range(counter, existing):
		click_boxes[i].hide()
	_update_valid_boxes_for_click()

"---------------------------- MEEPLE PLACEMENT ---------------------------------"

func _on_button_pressed() -> void:
	if not placing_meeple: return
	var index : int = int($VBoxContainer/SpinBox.value) - 1 # UI 1-based -> 0-based
	if not last_valids.has(index): return
	# para de aceitar input até a resposta
	placing_meeple = false
	meplacer.hide()
	meeple_placement_requested.emit(index)
	MO.success("meeple asked at index " + str(index))
