################################################################################
# CHỨC NĂNG:
#   Quản lý trạng thái tổng thể của CyberTank (điểm, màn, cờ game over, v.v.).
#   File này được dùng làm Autoload (singleton) để các hệ thống truy cập chung.
#
# NGƯỜI PHỤ TRÁCH:
#   [Thành viên 3 (Game Master, Core Logic & System)]
################################################################################

extends Node
class_name GameState


func _ready() -> void:
	pass


func reset_session() -> void:
	pass


func save_checkpoint() -> void:
	pass


func load_checkpoint() -> void:
	pass
