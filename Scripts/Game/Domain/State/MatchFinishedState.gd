class_name MatchFinishedState
extends TurnState

func enter() -> void:
	print("[State] Entrou no estado: MATCH_FINISHED (Jogo Encerrado)")

func get_name() -> String:
	return "MATCH_FINISHED"