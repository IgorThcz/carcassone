extends SubViewport

var card : AutoSkin

func set_card(id : int) -> bool:
	MO.sucess("AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA")
	var new_card : AutoSkin = Catalogue.get_skin(id)
	if not new_card:
		MO.error("set card returned")
		return false
	if card: card.queue_free()
	card = new_card
	add_child(card)
	card.global_position = Vector3.ZERO
	return true

func remove_card() -> void:
	card.queue_free()
