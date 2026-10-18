class_name ResolveScoreState
extends TurnState

func enter() -> void:
	print("[State] Entrou na fase: RESOLVE_SCORE")

func get_name() -> String:
	return "RESOLVE_SCORE"

func resolve_score() -> bool:
	# Após resolver a pontuação, o ciclo se completa e passa a vez
	machine.pass_turn()
	return true