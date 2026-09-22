extends Node

#minha ideia eh a gente utilizar essa classe como orquestrador do jogo.
#ela cuidaria de: do estado atual da partida; transicoes de estado; audio; entre outras coisas que forem convenientes
signal colorblind_mode_changed(enabled: bool)

var colorblind_mode: bool = false:
	set(value):
		if colorblind_mode != value:
			colorblind_mode = value
			colorblind_mode_changed.emit(value)

var current_match_config: Dictionary = {}