################################################################################
# CHỨC NĂNG:
#   Quản lý lưới TileMap: layer, ô có thể đi, highlight lượt và đồng bộ với logic game.
#
# NGƯỜI PHỤ TRÁCH:
#   [Thành viên 2 (UI, VFX & TileMap)]
################################################################################

extends TileMap
class_name GridManager


func _ready() -> void:
	pass


func world_to_cell(_world_pos: Vector2) -> Vector2i:
	return Vector2i.ZERO


func highlight_cell(_cell: Vector2i, _active: bool) -> void:
	pass


func refresh_from_game_state() -> void:
	pass
