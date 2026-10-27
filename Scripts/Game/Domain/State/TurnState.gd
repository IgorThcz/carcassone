class_name TurnState
extends RefCounted

## Interface / Classe Abstrata do Estado do Turno (GoF State Pattern)
## Define o contrato de ações permitidas em qualquer fase do turno.

var machine: TurnStateMachine

func _init(p_machine: TurnStateMachine) -> void:
	machine = p_machine

## Chamado ao entrar neste estado
func enter() -> void:
	pass

## Chamado ao sair deste estado
func exit() -> void:
	pass

## Nome identificador do estado
func get_name() -> String:
	return "TurnState"

# ---------------------------------------------------------------------------
# MÉTODOS VIRTUAIS 
# Se uma ação for chamada em uma fase inválida, o método base bloqueia a ação.
# ---------------------------------------------------------------------------

func draw_tile() -> bool:
	push_warning("[%s] Ação 'draw_tile' é inválida nesta fase." % get_name())
	return false

func place_tile(pos: Vector2i, rot: int) -> bool:
	push_warning("[%s] Ação 'place_tile' é inválida nesta fase." % get_name())
	return false

func place_meeple(slot_index: int) -> bool:
	push_warning("[%s] Ação 'place_meeple' é inválida nesta fase." % get_name())
	return false

func skip_meeple() -> bool:
	push_warning("[%s] Ação 'skip_meeple' é inválida nesta fase." % get_name())
	return false

func resolve_score() -> bool:
	push_warning("[%s] Ação 'resolve_score' é inválida nesta fase." % get_name())
	return false
