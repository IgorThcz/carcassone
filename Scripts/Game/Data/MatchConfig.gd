class_name MatchConfig
extends RefCounted

## DTO para as configurações da partida 

var players_data: Array[PlayerData] = []
var turn_time_limit: int = 60 
var total_tiles: int = 72      
var initial_card_id: int = 1   


func add_player_data(p_data: PlayerData) -> void:
	players_data.append(p_data)


func is_valid() -> bool:
	# Regra de negócio: Mínimo de 2 e máximo de 5 jogadores 
	if players_data.size() < 2 or players_data.size() > 5:
		push_warning("[MatchConfig] A partida deve ter entre 2 e 5 jogadores.")
		return false
	return true