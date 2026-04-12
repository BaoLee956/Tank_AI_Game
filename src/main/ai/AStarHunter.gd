################################################################################
# CHỨC NĂNG:
#   Tìm đường / lập kế hoạch di chuyển cho Hunter bằng A* (hoặc biến thể) trên lưới game.
#
# NGƯỜI PHỤ TRÁCH:
#   [Thành viên 1 (Lõi AI & Thuật toán)]
################################################################################

extends Node
class_name AStarHunter


func _ready() -> void:
	pass


func find_path(_from: Vector2i, _to: Vector2i) -> PackedVector2Array:
	return PackedVector2Array()


func update_navigation_graph() -> void:
	pass
