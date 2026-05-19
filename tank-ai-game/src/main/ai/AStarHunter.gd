################################################################################
# AStarHunter.gd – Tìm đường đi tối ưu cho Hunter bằng AStarGrid2D
#
# CHỨC NĂNG:
#   • Xây dựng lưới đi lại từ GridManager (walkable cells, không có tường).
#   • Tính đường đi từ ô A đến ô B, trả về danh sách pixel tâm các ô (bỏ qua ô đầu).
#   • Tự động cập nhật lại grid khi bản đồ thay đổi.
#
# NGƯỜI PHỤ TRÁCH: [Thành viên 1 (Lõi AI & Thuật toán)]
################################################################################

extends Node
class_name AStarHunter

@export var grid_manager: NodePath
var _grid: GridManager = null
var _astar_grid: AStarGrid2D = null

# Kích thước ô (pixel) – lấy từ GridManager
var _cell_size: Vector2 = Vector2(32, 32)


func _ready() -> void:
	if not grid_manager.is_empty():
		_grid = get_node(grid_manager) as GridManager
	else:
		push_error("AStarHunter: chưa gán grid_manager.")


func _build_navigation_grid() -> void:
	if _grid == null:
		return
	var walkable_cells: Array = _grid.get_walkable_cells()
	if walkable_cells.is_empty():
		return

	_astar_grid = AStarGrid2D.new()
	_astar_grid.region = Rect2i(0, 0, _grid.grid_width, _grid.grid_height)
	_astar_grid.cell_size = _cell_size
	_astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	_astar_grid.update()

	# Tất cả ô mặc định là solid
	for x in _grid.grid_width:
		for y in _grid.grid_height:
			_astar_grid.set_point_solid(Vector2i(x, y), true)

	# Bật các ô walkable
	for cell in walkable_cells:
		_astar_grid.set_point_solid(cell, false)

	for trap in GameState.traps:
		if is_instance_valid(trap) and trap is MineTrap:
			var trap_cell: Vector2i = _grid.local_center_to_cell((trap as Node2D).position)
			if _grid.is_in_bounds(trap_cell):
				_astar_grid.set_point_solid(trap_cell, true)

	GameState.prune_stale_references()
	for turret in GameState.turrets:
		if not is_instance_valid(turret) or not turret is Turret:
			continue
		var t_cell: Vector2i = GameState.get_entity_cell((turret as Turret).get_entity_id())
		if _grid.is_in_bounds(t_cell):
			_astar_grid.set_point_solid(t_cell, true)


func _pixel_to_cell(pixel: Vector2) -> Vector2i:
	return Vector2i(int(pixel.x / _cell_size.x), int(pixel.y / _cell_size.y))


## Tìm đường từ from_cell đến to_cell.
## Trả về PackedVector2Array chứa tọa độ pixel tâm (bỏ ô xuất phát).
func find_path(from_cell: Vector2i, to_cell: Vector2i) -> PackedVector2Array:
	if _astar_grid == null:
		_build_navigation_grid()
		if _astar_grid == null:
			return PackedVector2Array()

	if not _astar_grid.is_in_bounds(from_cell.x, from_cell.y) or not _astar_grid.is_in_bounds(to_cell.x, to_cell.y):
		return PackedVector2Array()
		
	if _astar_grid.is_point_solid(from_cell):
		_astar_grid.set_point_solid(from_cell, false)
	if _astar_grid.is_point_solid(to_cell):
		_astar_grid.set_point_solid(to_cell, false)

	# FIX: get_id_path trả về Array[Vector2i] (không phải PackedVector2iArray)
	var path_cells: Array[Vector2i] = _astar_grid.get_id_path(from_cell, to_cell)
	if path_cells.size() <= 1:
		return PackedVector2Array()

	# Bỏ ô đầu tiên (vị trí hiện tại)
	path_cells.remove_at(0)

	# Chuyển ô → pixel tâm
	var waypoints := PackedVector2Array()
	for cell in path_cells:
		waypoints.append(_grid.cell_to_local_center(cell))

	return waypoints


func update_navigation_graph() -> void:
	if _grid != null:
		_cell_size = Vector2(_grid.tile_size)
	_build_navigation_grid()
