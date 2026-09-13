class_name IOPlayer extends Player

# IMPLEMENTATION OF ABSTRACT SUPERCLASS
func _decide_card_placement(card_id: int, valid_positions: Dictionary[Vector2i, Array]) -> void:
	pass

func _decide_meeple_placement(meeple_valid_indexes: Array[int]) -> void:
	pass
