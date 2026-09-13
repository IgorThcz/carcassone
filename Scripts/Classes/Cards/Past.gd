class_name Past extends CardPart

func get_type() -> TYPES:
	return CardPart.TYPES.PAST

func calculate_points() -> int:
	# implementar depois
	return 0

func is_closed() -> bool:
	# implementar depois
	return false

func can_receive_meeple() -> bool:
	return true

func update() -> void:
	pass
