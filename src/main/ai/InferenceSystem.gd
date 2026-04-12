################################################################################
# CHỨC NĂNG:
#   Suy luận / cập nhật niềm tin về vị trí player và môi trường cho AI (Hunter, Turret...).
#
# NGƯỜI PHỤ TRÁCH:
#   [Thành viên 1 (Lõi AI & Thuật toán)]
################################################################################

extends Node
class_name InferenceSystem


func _ready() -> void:
	pass


func register_observation(_source: Node, _data: Dictionary) -> void:
	pass


func get_best_guess_position() -> Vector2:
	return Vector2.ZERO


func reset_beliefs() -> void:
	pass
