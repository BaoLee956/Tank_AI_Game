extends Node
class_name MapGenerator

@export var grid_manager: NodePath
@export var player_scene: PackedScene
@export var hunter_scene: PackedScene
@export var turret_scene: PackedScene
@export var enemy_base_scene: PackedScene
@export var mine_trap_scene: PackedScene
@export var emp_trap_scene: PackedScene

const ENTITY_SPRITE_SCALE: float = 0.42
const MIN_TURRETS: int = 2
const MIN_TRAPS: int = 8

var _grid: GridManager = null
var _reserved_cells: Dictionary = {}


func _ready() -> void:
	_ensure_grid()


func _ensure_grid() -> bool:
	if _grid != null:
		return true
	if grid_manager.is_empty():
		push_error("MapGenerator: thiếu grid_manager.")
		return false
	_grid = get_node_or_null(grid_manager) as GridManager
	if _grid == null:
		push_error("MapGenerator: không tìm thấy GridManager tại %s" % grid_manager)
	return _grid != null


func generate_map(seed_value: int = 0) -> void:
	if not _ensure_grid():
		return
	if _grid.entities_layer == null:
		push_error("MapGenerator: Entities layer null — hãy gọi generate_map sau khi GridManager._ready.")
		return

	seed(seed_value)
	_reserved_cells.clear()
	_grid.clear_all_entities()

	_grid.draw_ground()

	var player_cell := Vector2i(1, 1)
	var base_cell := Vector2i(_grid.grid_width - 2, _grid.grid_height - 2)
	_reserve_cell(player_cell)
	_reserve_cell(base_cell)

	var total_cells: int = _grid.grid_width * _grid.grid_height
	var wall_count: int = int(total_cells * randf_range(0.12, 0.18))
	for _i in range(wall_count):
		var cell := Vector2i(randi() % _grid.grid_width, randi() % _grid.grid_height)
		if not _is_reserved_cell(cell):
			_grid.set_wall(cell)

	_grid.mark_base_cell(base_cell)
	_spawn_entity(enemy_base_scene, base_cell)
	_spawn_entity(player_scene, player_cell)

	var hunter_cell := _find_walkable_cell_away_from(player_cell, 5)
	_spawn_entity(hunter_scene, hunter_cell)

	_spawn_turrets_near_base(base_cell)

	var trap_target: int = maxi(MIN_TRAPS, int(total_cells * 0.07))
	var traps_placed: int = 0
	var trap_attempts: int = 0
	while traps_placed < trap_target and trap_attempts < trap_target * 12:
		trap_attempts += 1
		var trap_cell := Vector2i(randi() % _grid.grid_width, randi() % _grid.grid_height)
		if not _grid.is_walkable(trap_cell) or _is_reserved_cell(trap_cell):
			continue
		if abs(trap_cell.x - player_cell.x) + abs(trap_cell.y - player_cell.y) < 3:
			continue
		_reserve_cell(trap_cell)
		var trap_scene: PackedScene = mine_trap_scene if randi() % 2 == 0 else emp_trap_scene
		_spawn_entity(trap_scene, trap_cell)
		traps_placed += 1

	_grid.snap_all_entities()

	var astar := get_node_or_null("../AStarHunter")
	if astar and astar.has_method("update_navigation_graph"):
		astar.update_navigation_graph()

	_validate_spawn(traps_placed)


func _spawn_turrets_near_base(base_cell: Vector2i) -> void:
	var candidates: Array[Vector2i] = _get_positions_around(base_cell, 2, 99)
	candidates.shuffle()
	var placed: int = 0
	for pos: Vector2i in candidates:
		if placed >= MIN_TURRETS:
			break
		if not _grid.is_in_bounds(pos) or _grid.is_wall(pos):
			continue
		if _is_reserved_cell(pos):
			continue
		_reserve_cell(pos)
		if _spawn_entity(turret_scene, pos):
			placed += 1
	if placed < MIN_TURRETS:
		push_warning("MapGenerator: chỉ đặt được %d/%d pháo quanh căn cứ." % [placed, MIN_TURRETS])


func _spawn_entity(scene: PackedScene, cell: Vector2i) -> bool:
	if scene == null:
		push_warning("MapGenerator: scene null — bỏ qua spawn tại %s" % cell)
		return false
	var instance: Node = scene.instantiate()
	if instance == null:
		push_warning("MapGenerator: instantiate thất bại cho %s" % scene.resource_path)
		return false
	if not instance is Node2D:
		push_warning("MapGenerator: %s không phải Node2D" % scene.resource_path)
		instance.queue_free()
		return false
	var node := instance as Node2D
	_prepare_entity_visual(node)
	_grid.place_entity(node, cell)
	return true


func _prepare_entity_visual(instance: Node2D) -> void:
	var hide_sprite := instance is MineTrap or instance is EMPTrap
	for child in instance.get_children():
		if child is Sprite2D:
			var spr := child as Sprite2D
			spr.scale = Vector2(ENTITY_SPRITE_SCALE, ENTITY_SPRITE_SCALE)
			spr.visible = not hide_sprite
			if not hide_sprite and spr.modulate.a < 0.1:
				spr.modulate = Color(1, 1, 1, 1)
	if hide_sprite and instance.has_method("_hide_visual"):
		instance.call("_hide_visual")


func _validate_spawn(trap_count: int) -> void:
	var n := _grid.entities_layer.get_child_count() if _grid.entities_layer else 0
	if n < 3:
		push_error("MapGenerator: quá ít entity trên map (%d). Kiểm tra scene export trong Main.tscn." % n)
	if GameState.hunter_ref == null:
		push_warning("MapGenerator: Hunter ref null sau khi sinh map.")
	if GameState.turrets.size() < MIN_TURRETS:
		push_warning("MapGenerator: thiếu pháo (%d)." % GameState.turrets.size())
	if trap_count < MIN_TRAPS:
		push_warning("MapGenerator: thiếu bẫy (%d)." % trap_count)


func _is_reserved_cell(cell: Vector2i) -> bool:
	return _reserved_cells.has(cell)


func _reserve_cell(cell: Vector2i) -> void:
	_reserved_cells[cell] = true


func _find_walkable_cell_away_from(from: Vector2i, min_distance: int) -> Vector2i:
	var candidates: Array[Vector2i] = _grid.get_walkable_cells()
	candidates.shuffle()
	for cell: Vector2i in candidates:
		if _is_reserved_cell(cell):
			continue
		var dist: int = abs(cell.x - from.x) + abs(cell.y - from.y)
		if dist >= min_distance:
			_reserve_cell(cell)
			return cell
	var fallback := from + Vector2i(3, 0)
	if _grid.is_in_bounds(fallback) and not _grid.is_wall(fallback):
		_reserve_cell(fallback)
		return fallback
	return from


func _get_positions_around(center: Vector2i, radius: int, _max_count: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for dx in range(-radius, radius + 1):
		for dy in range(-radius, radius + 1):
			var p := center + Vector2i(dx, dy)
			if p != center and _grid.is_in_bounds(p):
				result.append(p)
	return result
