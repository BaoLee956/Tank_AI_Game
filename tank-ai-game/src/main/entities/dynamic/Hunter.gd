extends Node2D
class_name Hunter

signal move_animation_requested(from_pos: Vector2, to_pos: Vector2)
signal player_spotted(player_cell: Vector2i)

const ENTITY_ID: StringName = &"hunter"
const ATTACK_DAMAGE: int = 100
const MOVE_DURATION: float = 0.2

var _cell: Vector2i = Vector2i(0, 0)
var _waypoints: PackedVector2Array = PackedVector2Array()
var _waypoint_index: int = 0
@export var astar_hunter_path: NodePath
var _astar: AStarHunter = null
var _cell_from_spawn: bool = false

@onready var sprite: Sprite2D = $Sprite2D


func set_cell(cell: Vector2i) -> void:
	_cell = cell
	_cell_from_spawn = true


func bind_astar(astar_node: AStarHunter) -> void:
	_astar = astar_node
	_request_new_path()


func _ready() -> void:
	if not _cell_from_spawn:
		_cell = _pixel_to_cell(position)
	GameState.hunter_ref = self
	GameState.register_entity(ENTITY_ID, _cell)
	_ensure_astar()
	TurnManager.hunter_phase_started.connect(_on_hunter_phase_started)


func _ensure_astar() -> void:
	if _astar != null:
		return
	if not astar_hunter_path.is_empty():
		_astar = get_node_or_null(astar_hunter_path) as AStarHunter


func _on_hunter_phase_started() -> void:
	if not is_instance_valid(self) or GameState.is_stunned(self):
		TurnManager.report_hunter_done()
		return

	var player_cell := GameState.get_entity_cell(&"player")
	if player_cell != Vector2i(-1, -1) and _can_shoot_player(player_cell):
		_attack_player()
		TurnManager.report_hunter_done()
		return

	_ensure_astar()
	if _astar and _astar.has_method("update_navigation_graph"):
		_astar.update_navigation_graph()
	_request_new_path()

	if _waypoints.is_empty():
		if _try_step_toward_player():
			return
		_trigger_no_escape()
		TurnManager.report_hunter_done()
		return

	_move_one_step()


func _can_shoot_player(player_cell: Vector2i) -> bool:
	return _is_adjacent(_cell, player_cell)


func _is_adjacent(a: Vector2i, b: Vector2i) -> bool:
	return abs(a.x - b.x) + abs(a.y - b.y) == 1


func _move_one_step() -> void:
	_ensure_astar()
	if _waypoints.is_empty() or _waypoint_index >= _waypoints.size():
		_request_new_path()
		if _waypoints.is_empty():
			if _try_step_toward_player():
				return
			_trigger_no_escape()
			TurnManager.report_hunter_done()
			return

	var next_pos: Vector2 = _waypoints[_waypoint_index]
	_waypoint_index += 1
	var grid := _get_grid()
	var next_cell: Vector2i
	if grid:
		next_cell = grid.local_center_to_cell(next_pos)
	else:
		next_cell = _pixel_to_cell(next_pos)

	var player_cell := GameState.get_entity_cell(&"player")
	if next_cell == player_cell:
		_cell = next_cell
		GameState.move_entity(ENTITY_ID, _cell)
		_attack_player()
		TurnManager.report_hunter_done()
		return

	var from_pos := position
	_cell = next_cell
	if grid:
		var target_pos := grid.cell_to_local_center(_cell)
		if sprite:
			var dir := target_pos - from_pos
			if abs(dir.x) >= abs(dir.y):
				sprite.flip_h = dir.x < 0
		var tween := create_tween()
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.set_trans(Tween.TRANS_QUAD)
		tween.tween_property(self, "position", target_pos, MOVE_DURATION)
		tween.finished.connect(_on_hunter_move_done.bind(from_pos, target_pos))
	else:
		position = _cell_to_pixel(_cell)
		_finish_hunter_move(from_pos, position)


func _on_hunter_move_done(from_pos: Vector2, to_pos: Vector2) -> void:
	_finish_hunter_move(from_pos, to_pos)


func _finish_hunter_move(from_pos: Vector2, to_pos: Vector2) -> void:
	GameState.move_entity(ENTITY_ID, _cell)
	emit_signal("move_animation_requested", from_pos, to_pos)
	_check_trap_on_cell()

	if GameState.is_game_active:
		var player_cell := GameState.get_entity_cell(&"player")
		if player_cell != Vector2i(-1, -1) and _can_shoot_player(player_cell):
			_attack_player()

	TurnManager.report_hunter_done()


func _check_trap_on_cell() -> void:
	var grid := _get_grid()
	if grid == null:
		return
	for trap in GameState.traps:
		if trap is MineTrap:
			continue
		if trap is EMPTrap:
			var trap_cell := grid.local_center_to_cell((trap as Node2D).position)
			if trap_cell == _cell:
				# Thêm dòng này để kích hoạt xẹt điện VFX của bẫy
				(trap as EMPTrap).activate_pulse() 
				
				# Phải CỘNG THÊM 1 VÀO LƯỢT CHOÁNG (giống như Player) để bù hao cho Phase Resolution
				GameState.apply_stun(self, GameState.EMP_STUN_TURNS + 1)
				return


func _attack_player() -> void:
	if is_instance_valid(GameState.player_ref) and GameState.player_ref is Player:
		(GameState.player_ref as Player).take_damage(
			ATTACK_DAMAGE,
			"Hunter bắn trúng — bạn ở trong tầm bắn!"
		)


func _try_step_toward_player() -> bool:
	var player_cell := GameState.get_entity_cell(&"player")
	if player_cell == Vector2i(-1, -1):
		return false
	var grid := _get_grid()
	if grid == null:
		return false
	var best := _cell
	var best_dist: int = absi(_cell.x - player_cell.x) + absi(_cell.y - player_cell.y)
	for dir: Vector2i in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]:
		var next := _cell + dir
		if not grid.is_in_bounds(next) or grid.is_wall(next):
			continue
		if GameState.is_cell_occupied(next):
			continue
		var d: int = absi(next.x - player_cell.x) + absi(next.y - player_cell.y)
		if d < best_dist:
			best_dist = d
			best = next
	if best == _cell:
		return false
	_cell = best
	position = grid.cell_to_local_center(_cell)
	GameState.move_entity(ENTITY_ID, _cell)
	if _can_shoot_player(player_cell):
		_attack_player()
	TurnManager.report_hunter_done()
	return true


func _trigger_no_escape() -> void:
	if not GameState.is_game_active:
		return
	if is_instance_valid(GameState.player_ref) and GameState.player_ref is Player:
		(GameState.player_ref as Player).take_damage(
			9999,
			"Không còn đường thoát — Hunter đã bao vây bạn!"
		)
	else:
		GameState.trigger_game_over("Không còn đường thoát — Hunter đã bao vây bạn!")


func _request_new_path() -> void:
	_ensure_astar()
	if _astar == null:
		return
	var player_cell := GameState.get_entity_cell(&"player")
	if player_cell == Vector2i(-1, -1):
		return
	set_path_waypoints(_astar.find_path(_cell, player_cell))


func set_path_waypoints(waypoints: PackedVector2Array) -> void:
	_waypoints = waypoints
	_waypoint_index = 0


func _get_grid() -> GridManager:
	var p := get_parent()
	if p and p.name == "Entities":
		return p.get_parent() as GridManager
	return get_node_or_null("/root/Main/GridManager") as GridManager


func _cell_to_pixel(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * 32 + 16, cell.y * 32 + 16)


func _pixel_to_cell(pixel: Vector2) -> Vector2i:
	return Vector2i(int(pixel.x / 32), int(pixel.y / 32))
