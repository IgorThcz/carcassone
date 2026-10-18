@abstract class_name View extends Node3D

# Sinais para comunicar com a UI Overlay / GameController
signal tile_placement_requested(grid_pos: Vector2i, rot: CardStructure.CARDROTATION)
signal meeple_placement_requested(card_pos: Vector2i, meeple_index: int)

@abstract
func add_card(pos: Vector2i, id : int, rot : CardStructure.CARDROTATION) -> void

@abstract
func add_meeple(card_pos: Vector2i, meeple_index : int) -> void

@abstract
func remove_meeple(card_pos: Vector2i) -> void

@abstract
func place_mode(vadjacents: Array[Vector2i]) -> void

@abstract
func click_box_selected(box: Node3D) -> void
