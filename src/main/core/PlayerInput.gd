################################################################################
# CHỨC NĂNG:
#   Thu thập và chuẩn hóa input từ người chơi (bàn phím/chuột/gamepad) cho tank và UI.
#
# NGƯỜI PHỤ TRÁCH:
#   [Thành viên 3 (Game Master, Core Logic & System)]
################################################################################

extends Node
class_name PlayerInput

var _action_allowed: bool = true


func _ready() -> void:
	pass


func _unhandled_input(_event: InputEvent) -> void:
	pass


func is_action_allowed() -> bool:
	return _action_allowed


func set_action_allowed(allowed: bool) -> void:
	_action_allowed = allowed


func consume_move_command() -> void:
	pass