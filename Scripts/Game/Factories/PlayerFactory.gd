class_name PlayerFactory
extends RefCounted

## Fábrica responsável pela instanciação polimórfica de jogadores e injeção de estratégias.

static func create_player(data: PlayerData) -> Player:
	if data == null:
		push_error("[PlayerFactory] Tentativa de criar jogador com PlayerData nulo.")
		return null

	if data.is_ai:
		var ai_strategy: AIStrategy
		match data.ai_difficulty:
			PlayerData.Difficulty.ADVANCED:
				ai_strategy = AdvancedAIStrategy.new()
			_:
				ai_strategy = BasicAIStrategy.new()

		return AIPlayer.new(
			data.id, 
			data.name, 
			data.color, 
			ai_strategy
		)
		
	return IOPlayer.new(
		data.id, 
		data.name, 
		data.color
	)


static func create_players(config: MatchConfig) -> Array[Player]:
	var players: Array[Player] = []
	for data in config.players_data:
		var player: Player = create_player(data)
		if player:
			players.append(player)
	return players