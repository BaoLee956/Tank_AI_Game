################################################################################
# CHỨC NĂNG:
#   Tập trung spawn / pool các hiệu ứng hạt (nổ, khói, tia) để tái sử dụng hiệu năng.
#
# NGƯỜI PHỤ TRÁCH:
#   [Thành viên 2 (UI, VFX & TileMap)]
################################################################################

extends Node2D
class_name ParticleManager


func _ready() -> void:
	pass


func play_effect_at(_effect_id: StringName, _world_position: Vector2) -> void:
	pass


func recycle_effect(_instance: Node) -> void:
	pass
