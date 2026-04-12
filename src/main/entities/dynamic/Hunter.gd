################################################################################
# CHỨC NĂNG:
#   Entity Hunter: hành vi đuổi/tấn công, đồng bộ với hệ thống đường đi AI.
#
# NGƯỜI PHỤ TRÁCH:
#   [Thành viên 3 (Game Master, Core Logic & System)] — Logic
#   [Thành viên 1 (Lõi AI & Thuật toán)] — Đường đi
################################################################################

extends Node2D
class_name Hunter


func _ready() -> void:
	pass


func _physics_process(_delta: float) -> void:
	pass


func set_path_waypoints(_waypoints: PackedVector2Array) -> void:
	pass


func on_player_spotted() -> void:
	pass
