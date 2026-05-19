################################################################################
# InferenceSystem.gd – Hệ thống suy luận vị trí của Player cho Hunter / Turret
#
# CHỨC NĂNG:
#   • Lưu lại những quan sát về vị trí Player (khi Hunter nhìn thấy).
#   • Cung cấp vị trí ước lượng tốt nhất (gần đây nhất) để AI truy đuổi khi mất dấu.
#   • Có thể mở rộng thành bộ lọc particle nâng cao.
#
# NGƯỜI PHỤ TRÁCH: [Thành viên 1 (Lõi AI & Thuật toán)]
################################################################################

extends Node
class_name InferenceSystem

var _last_seen_cell: Vector2i = Vector2i(-1, -1)
var _last_seen_turn: int = -1
var _observed_positions: Array[Vector2i] = []


func _ready() -> void:
	# FIX: không dùng TurnManager.is_connected() với cú pháp Callable cũ.
	# Hunter sẽ gọi trực tiếp register_observation() khi cần.
	pass


## Đăng ký quan sát vị trí Player (thường gọi từ Hunter khi phát hiện).
## data: { "cell": Vector2i, "turn": int }
func register_observation(source: Node, data: Dictionary) -> void:
	if data.has("cell") and data["cell"] is Vector2i:
		_last_seen_cell = data["cell"]
		_last_seen_turn = data.get("turn", GameState.current_turn)
		_observed_positions.append(_last_seen_cell)
		if _observed_positions.size() > 10:
			_observed_positions.remove_at(0)


## Trả về vị trí pixel ước lượng tốt nhất của Player.
func get_best_guess_position() -> Vector2:
	if _last_seen_cell != Vector2i(-1, -1):
		var grid_manager: GridManager = get_node_or_null("/root/Main/GridManager")
		if grid_manager:
			return grid_manager.map_to_local(_last_seen_cell) + Vector2(32.0, 32.0)
	return Vector2.ZERO


## Trả về ô cuối cùng nhìn thấy.
func get_last_seen_cell() -> Vector2i:
	return _last_seen_cell


## Reset khi bắt đầu ván mới.
func reset_beliefs() -> void:
	_last_seen_cell = Vector2i(-1, -1)
	_last_seen_turn = -1
	_observed_positions.clear()