################################################################################
# CHỨC NĂNG:
#   Entity tank người chơi: vị trí, hướng, tương tác va chạm và hook cho animation.
#
# NGƯỜI PHỤ TRÁCH:
#   [Thành viên 3 (Game Master, Core Logic & System)] — Logic
#   [Thành viên 2 (UI, VFX & TileMap)] — Animation
################################################################################

extends Node2D
class_name Player


func _ready() -> void:
	pass


func _physics_process(_delta: float) -> void:
	pass


func apply_move_intent(_direction: Vector2) -> void:
	pass


func take_damage(_amount: int) -> void:
	pass
