################################################################################
# PlayerInput.gd — Thu thập và chuẩn hoá input từ người chơi
#
# CHỨC NĂNG:
#   • Lắng nghe click chuột trái (di chuyển) và phải (bắn đạn).
#   • Chuẩn hoá tọa độ màn hình → tọa độ ô lưới (cell) qua GridManager.
#   • Chặn input khi _action_allowed = false (pha AI đang chạy, game over...).
#   • Phát signal để Player.gd và TurnManager.gd xử lý logic.
#
# KẾT NỐI:
#   Trong scene chính, kết nối:
#       PlayerInput.move_requested  → Player.apply_move_intent  (hoặc xử lý trực tiếp)
#       PlayerInput.shoot_requested → Bullet spawn logic
#
# NGƯỜI PHỤ TRÁCH:
#   [Thành viên 3 (Game Master, Core Logic & System)]
################################################################################

extends Node
class_name PlayerInput

# ═══════════════════════════════════════════════════════════════════════════════
# SIGNALS
# ═══════════════════════════════════════════════════════════════════════════════

## Phát khi người chơi click trái lên một ô hợp lệ để di chuyển.
signal move_requested(target_cell: Vector2i)

## Phát khi người chơi click phải lên một ô để bắn đạn.
signal shoot_requested(target_cell: Vector2i)

# ═══════════════════════════════════════════════════════════════════════════════
# TRẠNG THÁI
# ═══════════════════════════════════════════════════════════════════════════════

## Cho phép / chặn mọi hành động input. TurnManager set = false khi đến pha AI.
var _action_allowed: bool = false

## Tham chiếu đến GridManager (Member 2) để chuyển đổi tọa độ.
## Gán từ scene chính: player_input.grid_manager = $GridManager
@export var grid_manager: NodePath

var _grid_ref: GridManager = null

# ── Lệnh di chuyển đang chờ xử lý (consume pattern) ─────────────────────────
var _pending_move: Vector2i = Vector2i(-1, -1)
var _has_pending_move: bool = false

# ═══════════════════════════════════════════════════════════════════════════════
# KHỞI TẠO
# ═══════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	if not grid_manager.is_empty():
		_grid_ref = get_node(grid_manager) as GridManager
	# Kết nối TurnManager: cho phép input khi đến lượt Player.
	TurnManager.player_turn_started.connect(_on_player_turn_started)
	TurnManager.player_turn_ended.connect(_on_player_turn_ended)


# ═══════════════════════════════════════════════════════════════════════════════
# XỬ LÝ INPUT
# ═══════════════════════════════════════════════════════════════════════════════

func _unhandled_input(event: InputEvent) -> void:
	if not _action_allowed or not GameState.is_game_active:
		return

	if event is InputEventMouseButton and event.pressed:
		var mouse_event := event as InputEventMouseButton
		if not _grid_ref.is_world_on_grid(mouse_event.global_position):
			return
		var cell: Vector2i = _grid_ref.world_to_cell(mouse_event.global_position)
		if cell == Vector2i(-1, -1):
			return

		match mouse_event.button_index:
			MOUSE_BUTTON_LEFT:
				_handle_move_request(cell)
			MOUSE_BUTTON_RIGHT:
				_handle_shoot_request(cell)


# ── Di chuyển (click trái) ───────────────────────────────────────────────────
func _handle_move_request(cell: Vector2i) -> void:
	# Player chỉ di chuyển được 1 ô mỗi lượt → lưu pending và phát signal.
	_pending_move = cell
	_has_pending_move = true
	set_action_allowed(false)
	emit_signal("move_requested", cell)


# ── Bắn đạn (click phải) ─────────────────────────────────────────────────────
func _handle_shoot_request(cell: Vector2i) -> void:
	if not GameState.has_bullets():
		# Không còn đạn, bỏ qua (HUD đã hiển thị 0)
		return
	set_action_allowed(false)
	emit_signal("shoot_requested", cell)


# ═══════════════════════════════════════════════════════════════════════════════
# API CÔNG KHAI
# ═══════════════════════════════════════════════════════════════════════════════

func is_action_allowed() -> bool:
	return _action_allowed


func set_action_allowed(allowed: bool) -> void:
	_action_allowed = allowed


## Lấy và xoá lệnh di chuyển đang chờ (consume pattern).
## Player.gd gọi hàm này để đọc target cell.
func consume_move_command() -> Vector2i:
	if not _has_pending_move:
		return Vector2i(-1, -1)
	var cmd := _pending_move
	_pending_move = Vector2i(-1, -1)
	_has_pending_move = false
	return cmd


# ═══════════════════════════════════════════════════════════════════════════════
# NỘI BỘ
# ═══════════════════════════════════════════════════════════════════════════════

func _world_to_cell(world_pos: Vector2) -> Vector2i:
	if _grid_ref == null:
		push_warning("PlayerInput: grid_manager chưa được gán.")
		return Vector2i(-1, -1)
	var cell := _grid_ref.world_to_cell(world_pos)
	if not _grid_ref.is_in_bounds(cell):
		return Vector2i(-1, -1)
	return cell


func _on_player_turn_started() -> void:
	set_action_allowed(true)


func _on_player_turn_ended() -> void:
	set_action_allowed(false)
