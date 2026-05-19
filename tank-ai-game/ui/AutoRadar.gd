extends Node
class_name AutoRadar

## Radar tự động: lấy vị trí player, quét các ô có thể bước tới, đánh dấu mối ẩn.

@export var grid_manager_path: NodePath
var _grid: GridManager = null


func _ready() -> void:
	if not grid_manager_path.is_empty():
		_grid = get_node(grid_manager_path) as GridManager
	TurnManager.player_turn_started.connect(_on_player_turn_started)
	GameState.entity_moved.connect(_on_entity_moved)
	TurnManager.player_turn_ended.connect(_on_player_turn_ended)
	TurnManager.turn_complete.connect(_on_turn_complete)


func assign_grid(g: GridManager) -> void:
	_grid = g


func _on_player_turn_started() -> void:
	_refresh()


func _on_entity_moved(entity_id: StringName, _from: Vector2i, _to: Vector2i) -> void:
	if entity_id == &"player":
		_refresh()


func _on_player_turn_ended() -> void:
	_clear()


func _on_turn_complete(_turn_number: int) -> void:
	if TurnManager.current_phase == TurnManager.Phase.IDLE:
		_clear()


func _refresh() -> void:
	if _grid == null or not GameState.is_game_active:
		_clear()
		return
	var player_cell := GameState.get_entity_cell(&"player")
	if player_cell == Vector2i(-1, -1):
		_clear()
		return

	var pings: Array[Vector2i] = []
	for dir: Vector2i in [
		Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN
	]:
		var step := player_cell + dir
		if not _grid.is_walkable(step, &"player"):
			continue
		if _has_hidden_threat_at(step):
			pings.append(step)

	_grid.set_radar_ping_cells(pings)


func _has_hidden_threat_at(cell: Vector2i) -> bool:
	for trap in GameState.traps:
		if not is_instance_valid(trap) or not trap is Node2D:
			continue
		if _grid.local_center_to_cell((trap as Node2D).position) == cell:
			return true
	if is_instance_valid(GameState.hunter_ref):
		if GameState.get_entity_cell(&"hunter") == cell:
			return true
	return false


func _clear() -> void:
	if _grid:
		_grid.set_radar_ping_cells([])
