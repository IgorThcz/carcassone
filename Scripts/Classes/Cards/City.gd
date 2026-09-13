class_name City extends CardPart

func can_receive_meeple() -> bool:
	return true

func get_type() -> TYPES:
	return CardPart.TYPES.CITY

func calculate_points() -> int:
	# implementar depois
	return 0

func is_closed() -> bool:
	# implementar depois
	return false

func update() -> void:
	return
