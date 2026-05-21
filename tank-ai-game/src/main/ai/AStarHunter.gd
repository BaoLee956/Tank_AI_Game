extends Node
class_name AStarHunter

@export var grid_manager: NodePath
var _grid: GridManager = null
var _cell_size: Vector2 = Vector2(32, 32)

# Bản đồ tự chế thay thế cho AStarGrid2D
# Cấu trúc: { Vector2i(x, y): true (là tường/vật cản) hoặc false (đi được) }
var _solid_cells: Dictionary = {} 

func _ready() -> void:
	if not grid_manager.is_empty():
		_grid = get_node(grid_manager) as GridManager
	else:
		push_error("AStarHunter: chưa gán grid_manager.")

func _build_navigation_grid() -> void:
	_solid_cells.clear()
	if _grid == null:
		return
		
	var walkable_cells: Array = _grid.get_walkable_cells()
	
	# Mặc định tất cả các ô trên bản đồ đều là tường (true)
	for x in _grid.grid_width:
		for y in _grid.grid_height:
			_solid_cells[Vector2i(x, y)] = true

	# Bật các ô walkable thành đường đi (false)
	for cell in walkable_cells:
		_solid_cells[cell] = false

	# Chặn Mìn
	for trap in GameState.traps:
		if is_instance_valid(trap) and trap is MineTrap:
			var trap_cell: Vector2i = _grid.local_center_to_cell((trap as Node2D).position)
			if _grid.is_in_bounds(trap_cell):
				_solid_cells[trap_cell] = true

	# Chặn Pháo
	GameState.prune_stale_references()
	for turret in GameState.turrets:
		if not is_instance_valid(turret) or not turret is Turret:
			continue
		var t_cell: Vector2i = GameState.get_entity_cell((turret as Turret).get_entity_id())
		if _grid.is_in_bounds(t_cell):
			_solid_cells[t_cell] = true


# 1. HÀM HEURISTIC - Dự đoán khoảng cách (Manhattan)
func _heuristic(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)


# 2. HÀM TÌM ĐƯỜNG CỐT LÕI
func find_path(from_cell: Vector2i, to_cell: Vector2i) -> PackedVector2Array:
	_build_navigation_grid() # Cập nhật chướng ngại vật mới nhất

	# Mở khóa ô xuất phát và ô đích để cho phép thuật toán tính toán
	_solid_cells[from_cell] = false
	_solid_cells[to_cell] = false

	# Khởi tạo các biến chuẩn của thuật toán A*
	var open_set: Array[Vector2i] = [from_cell]
	var came_from: Dictionary = {} # Lưu vết đường đi
	
	var g_score: Dictionary = {} # Chi phí thực tế từ điểm xuất phát
	g_score[from_cell] = 0
	
	var f_score: Dictionary = {} # F = G + Heuristic
	f_score[from_cell] = _heuristic(from_cell, to_cell)

	# Vòng lặp duyệt tìm đường
	while open_set.size() > 0:
		# Lấy ra ô có điểm F thấp nhất trong open_set
		var current = open_set[0]
		var current_index = 0
		for i in range(1, open_set.size()):
			var cell = open_set[i]
			if f_score.get(cell, 999999) < f_score.get(current, 999999):
				current = cell
				current_index = i

		# Nếu đã chạm đến đích, tiến hành truy xuất ngược lại con đường
		if current == to_cell:
			return _reconstruct_path(came_from, current)

		# Đã xét xong ô này, loại bỏ nó
		open_set.remove_at(current_index)

		# Duyệt 4 hướng kề cạnh
		var neighbors = [
			current + Vector2i.RIGHT, current + Vector2i.LEFT,
			current + Vector2i.UP, current + Vector2i.DOWN
		]

		for neighbor in neighbors:
			# Bỏ qua nếu là ô Tường, Mìn, Pháo hoặc ngoài map
			if _solid_cells.get(neighbor, true) == true:
				continue

			# G_score đi sang ô bên cạnh luôn tốn 1 bước
			var tentative_g_score = g_score[current] + 1

			# Nếu tìm được đường đi tới neighbor ngắn hơn đường cũ (hoặc chưa từng đi)
			if tentative_g_score < g_score.get(neighbor, 999999):
				came_from[neighbor] = current # Ghi nhớ vết
				g_score[neighbor] = tentative_g_score
				f_score[neighbor] = tentative_g_score + _heuristic(neighbor, to_cell)

				# Thêm neighbor vào danh sách cần xét nếu nó chưa có
				if not open_set.has(neighbor):
					open_set.append(neighbor)

	# Nếu vòng lặp kết thúc mà không return, nghĩa là kẹt không có đường đi
	return PackedVector2Array()


# 3. HÀM TẠO LẠI ĐƯỜNG ĐI SAU KHI ĐÃ TÌM ĐƯỢC
func _reconstruct_path(came_from: Dictionary, current: Vector2i) -> PackedVector2Array:
	var path_cells: Array[Vector2i] = [current]
	
	# Lần ngược từ đích về điểm xuất phát qua mảng came_from
	while came_from.has(current):
		current = came_from[current]
		path_cells.insert(0, current) # Nhét vào đầu mảng

	# Bỏ ô đầu tiên (vị trí hiện tại đang đứng)
	path_cells.remove_at(0)

	# Chuyển đổi từ tọa độ Cell sang tọa độ Pixel cho Hunter chạy
	var waypoints := PackedVector2Array()
	for cell in path_cells:
		waypoints.append(_grid.cell_to_local_center(cell))

	return waypoints

func update_navigation_graph() -> void:
	if _grid != null:
		_cell_size = Vector2(_grid.tile_size)
	_build_navigation_grid()
