################################################################################
# CHỨC NĂNG:
#   Căn cứ địch: vùng mục tiêu, HP / trạng thái phá hủy và điều kiện thắng thua.
#
# NGƯỜI PHỤ TRÁCH:
#   [Thành viên 3 (Game Master, Core Logic & System)]
################################################################################

extends Area2D
class_name EnemyBase


func _ready() -> void:
	pass


func register_hit(_damage: int) -> void:
	pass


func is_destroyed() -> bool:
	return false


func _on_body_entered(_body: Node2D) -> void:
	pass
