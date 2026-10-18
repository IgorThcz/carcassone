class_name PlayerData
extends RefCounted

## Objeto de Transferência de Dados (DTO) para os parâmetros de um Jogador.

enum Difficulty { BASIC, ADVANCED }

var id: String = ""
var name: String = ""
var color: Color = Color.WHITE
var is_ai: bool = false
var ai_difficulty: Difficulty = Difficulty.BASIC


func _init(
	p_id: String, 
	p_name: String, 
	p_color: Color = Color.WHITE, 
	p_is_ai: bool = false, 
	p_ai_difficulty: Difficulty = Difficulty.BASIC
) -> void:
	id = p_id
	name = p_name
	color = p_color
	is_ai = p_is_ai
	ai_difficulty = p_ai_difficulty