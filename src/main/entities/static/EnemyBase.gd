################################################################################
# CHỨC NĂNG:
#   Căn cứ địch: vùng mục tiêu, HP / trạng thái phá hủy và điều kiện thắng thua.
#
# NGƯỜI PHỤ TRÁCH:
#   [Thành viên 3 (Game Master, Core Logic & System)]
################################################################################

extends Area2D
class_name EnemyBase

var _health: int = 100


func _ready() -> void:
	pass


func register_hit(damage: int) -> void:
	if damage <= 0:
		return
	_health = maxi(0, _health - damage)


func is_destroyed() -> bool:
	return _health <= 0


func _on_body_entered(_body: Node2D) -> void:
	pass
