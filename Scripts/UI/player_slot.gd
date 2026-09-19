extends PanelContainer
class_name PlayerSlot

enum SlotMode { AI, HUMAN, DISABLED }

signal mode_changed(slot: PlayerSlot, new_mode: SlotMode)

@export var default_name: String = "JOGADOR"
@export var slot_color: Color = Color.WHITE

var current_mode: SlotMode = SlotMode.DISABLED

@onready var color_box: ColorRect = %ColorBox
@onready var name_label: Label = %NameLabel
@onready var status_label: Label = %StatusLabel
@onready var btn_ai: Button = %BtnAI
@onready var btn_human: Button = %BtnHuman
@onready var btn_off: Button = %BtnOff

func _ready() -> void:
	color_box.color = slot_color
	name_label.text = default_name
	
	btn_ai.pressed.connect(func(): set_mode(SlotMode.AI))
	btn_human.pressed.connect(func(): set_mode(SlotMode.HUMAN))
	btn_off.pressed.connect(func(): set_mode(SlotMode.DISABLED))

func set_mode(mode: SlotMode) -> void:
	current_mode = mode
	_update_ui()
	mode_changed.emit(self, current_mode)

func _update_ui() -> void:
	match current_mode:
		SlotMode.HUMAN:
			status_label.text = "[Jogador]"
			modulate = Color(1, 1, 1, 1.0)
		SlotMode.AI:
			status_label.text = "[CPU]"
			modulate = Color(1, 1, 1, 1.0)
		SlotMode.DISABLED:
			status_label.text = "Vago"
			modulate = Color(0.5, 0.5, 0.5, 0.6)