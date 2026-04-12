################################################################################
# CHỨC NĂNG:
#   Thu thập và chuẩn hóa input từ người chơi (bàn phím/chuột/gamepad) cho tank và UI.
#
# NGƯỜI PHỤ TRÁCH:
#   [Thành viên 3 (Game Master, Core Logic & System)]
################################################################################

extends Node
class_name PlayerInput


func _ready() -> void:
	pass


func _unhandled_input(_event: InputEvent) -> void:
	pass


func is_action_allowed() -> bool:
	return false


func consume_move_command() -> void:
	pass
