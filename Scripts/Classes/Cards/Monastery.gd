class_name Monastery extends CardPart

func get_type() -> TYPES:
	return CardPart.TYPES.MONASTERY

func calculate_points() -> int:
	# implementar depois
	return 0

func is_closed() -> bool:
	return true

func can_receive_meeple() -> bool:
	if base_card.has_meeple or occupier:
		return false
	return true

func update() -> void:
	pass
