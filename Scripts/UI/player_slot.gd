extends PanelContainer
class_name PlayerSlot

enum SlotMode { AI, HUMAN, DISABLED }

signal mode_changed(slot: PlayerSlot, new_mode: SlotMode)
signal ai_difficulty_changed(slot: PlayerSlot, difficulty: PlayerData.Difficulty)

@export var default_name: String = "JOGADOR"
@export var slot_color: Color = Color.WHITE

var current_mode: SlotMode = SlotMode.DISABLED
var ai_difficulty: PlayerData.Difficulty = PlayerData.Difficulty.BASIC

@onready var color_box: ColorRect = %ColorBox
@onready var name_label: Label = %NameLabel
@onready var status_label: Label = %StatusLabel
@onready var btn_ai: Button = %BtnAI
@onready var btn_human: Button = %BtnHuman
@onready var btn_off: Button = %BtnOff


func _ready() -> void:
	color_box.color = slot_color
	name_label.text = default_name
	
	btn_ai.pressed.connect(_on_btn_ai_pressed)
	btn_human.pressed.connect(func(): set_mode(SlotMode.HUMAN))
	btn_off.pressed.connect(func(): set_mode(SlotMode.DISABLED))


func set_mode(mode: SlotMode) -> void:
	current_mode = mode
	_update_ui()
	mode_changed.emit(self, current_mode)


func set_color(new_color: Color) -> void:
	slot_color = new_color
	if color_box:
		color_box.color = slot_color


func set_ai_difficulty(difficulty: PlayerData.Difficulty) -> void:
	ai_difficulty = difficulty
	if current_mode == SlotMode.AI:
		_update_ui()
	ai_difficulty_changed.emit(self, ai_difficulty)


## Callback do botão CPU: Define como IA ou alterna a dificuldade se já for IA
func _on_btn_ai_pressed() -> void:
	if current_mode == SlotMode.AI:
		var new_diff: PlayerData.Difficulty = (
			PlayerData.Difficulty.ADVANCED 
			if ai_difficulty == PlayerData.Difficulty.BASIC 
			else PlayerData.Difficulty.BASIC
		)
		set_ai_difficulty(new_diff)
	else:
		set_mode(SlotMode.AI)


func _update_ui() -> void:
	match current_mode:
		SlotMode.HUMAN:
			status_label.text = "[Jogador]"
			modulate = Color(1, 1, 1, 1.0)
		SlotMode.AI:
			var diff_text: String = "BÁSICA" if ai_difficulty == PlayerData.Difficulty.BASIC else "AVANÇADA"
			status_label.text = "[CPU - %s]" % diff_text
			modulate = Color(1, 1, 1, 1.0)
		SlotMode.DISABLED:
			status_label.text = "Vago"
			modulate = Color(0.5, 0.5, 0.5, 0.6)
