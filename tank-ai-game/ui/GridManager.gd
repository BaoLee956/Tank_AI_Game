extends Node2D
class_name GridManager

const TILESET_SOURCE_ID: int = 0

const TILE_FLOOR_A: Vector2i = Vector2i(0, 0)
const TILE_FLOOR_B: Vector2i = Vector2i(4, 0)
const TILE_WALL: Vector2i = Vector2i(1, 0)
const TILE_BASE: Vector2i = Vector2i(2, 0)
const TILE_MOVE_HL: Vector2i = Vector2i(0, 1)
const TILE_ATTACK_HL: Vector2i = Vector2i(1, 1)

@export var grid_width: int = 12
@export var grid_height: int = 12

@onready var ground_layer: TileMapLayer = $GroundLayer
@onready var objects_layer: TileMapLayer = $ObjectsLayer
@onready var highlight_layer: TileMapLayer = $HighlightLayer
@onready var grid_overlay: Node2D = $GridOverlay
@onready var entities_layer: Node2D = $Entities

var _highlighted_cells: Array[Vector2i] = []
var _turret_marks: Dictionary = {}
var _radar_cells: Array[Vector2i] = []


func _ready() -> void:
	if not ground_layer or not objects_layer or not highlight_layer:
		push_error("GridManager: thiếu TileMapLayer con.")
		return
	_sync_tilemap_settings()
	_update_grid_overlay()
	GameState.entity_moved.connect(_on_entity_moved)


func _sync_tilemap_settings() -> void:
	for layer: TileMapLayer in [ground_layer, objects_layer, highlight_layer]:
		layer.y_sort_enabled = false
		if layer.tile_set:
			layer.tile_set.tile_size = Vector2i(32, 32)


func _update_grid_overlay() -> void:
	if grid_overlay and grid_overlay.has_method("configure"):
		grid_overlay.call("configure", grid_width, grid_height, tile_size)


# ── Tọa độ thống nhất (không phụ thuộc map_to_local của TileMap) ─────────────
func cell_to_local_center(cell: Vector2i) -> Vector2:
	var ts := tile_size
	return Vector2((cell.x + 0.5) * ts.x, (cell.y + 0.5) * ts.y)


func cell_top_left(cell: Vector2i) -> Vector2:
	var ts := tile_size
	return Vector2(cell.x * ts.x, cell.y * ts.y)


func get_map_pixel_size() -> Vector2:
	var ts := tile_size
	return Vector2(grid_width * ts.x, grid_height * ts.y)


func is_local_on_grid(local_pos: Vector2) -> bool:
	var map_size := get_map_pixel_size()
	return local_pos.x >= 0.0 and local_pos.y >= 0.0 \
		and local_pos.x < map_size.x and local_pos.y < map_size.y


func local_to_cell(local_pos: Vector2) -> Vector2i:
	if not is_local_on_grid(local_pos):
		return Vector2i(-1, -1)
	var ts := tile_size
	return Vector2i(
		int(floor(local_pos.x / float(ts.x))),
		int(floor(local_pos.y / float(ts.y)))
	)


func world_to_cell(world_pos: Vector2) -> Vector2i:
	return local_to_cell(to_local(world_pos))


func is_world_on_grid(world_pos: Vector2) -> bool:
	return is_local_on_grid(to_local(world_pos))


func cell_to_world_center(cell: Vector2i) -> Vector2:
	return to_global(cell_to_local_center(cell))


func local_center_to_cell(local_pos: Vector2) -> Vector2i:
	return local_to_cell(local_pos)


var tile_size: Vector2i:
	get:
		if ground_layer != null and ground_layer.tile_set != null:
			return ground_layer.tile_set.tile_size
		return Vector2i(32, 32)


# ── Vẽ bản đồ ────────────────────────────────────────────────────────────────
func draw_ground() -> void:
	for x in range(grid_width):
		for y in range(grid_height):
			var atlas := TILE_FLOOR_A if (x + y) % 2 == 0 else TILE_FLOOR_B
			ground_layer.set_cell(Vector2i(x, y), TILESET_SOURCE_ID, atlas)


func set_wall(cell: Vector2i) -> void:
	ground_layer.set_cell(cell, TILESET_SOURCE_ID, TILE_WALL)


func mark_base_cell(cell: Vector2i) -> void:
	ground_layer.set_cell(cell, TILESET_SOURCE_ID, TILE_BASE)


func clear_cell_highlight(cell: Vector2i) -> void:
	highlight_layer.erase_cell(cell)


func highlight_cell(cell: Vector2i, active: bool) -> void:
	if active:
		highlight_layer.set_cell(cell, TILESET_SOURCE_ID, TILE_MOVE_HL)
		if not _highlighted_cells.has(cell):
			_highlighted_cells.append(cell)
	else:
		highlight_layer.erase_cell(cell)
		_highlighted_cells.erase(cell)


func clear_move_highlights() -> void:
	for cell: Vector2i in _highlighted_cells:
		if not _turret_marks.has(cell):
			highlight_layer.erase_cell(cell)
	_highlighted_cells.clear()


func clear_all_highlights() -> void:
	clear_move_highlights()


func highlight_player_moves(player_cell: Vector2i) -> void:
	clear_move_highlights()
	for dir: Vector2i in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]:
		var target := player_cell + dir
		if is_walkable(target, &"player"):
			highlight_cell(target, true)


func set_turret_target(cell: Vector2i, phase: String) -> void:
	if cell == Vector2i(-1, -1):
		return
	match phase:
		"lock":
			_turret_marks[cell] = Color(1.0, 0.88, 0.1)
			highlight_layer.set_cell(cell, TILESET_SOURCE_ID, TILE_MOVE_HL)
		"fire":
			_turret_marks[cell] = Color(1.0, 0.18, 0.12)
			highlight_layer.set_cell(cell, TILESET_SOURCE_ID, TILE_ATTACK_HL)
	_sync_overlay()


func clear_turret_target(cell: Vector2i) -> void:
	if _turret_marks.erase(cell):
		highlight_layer.erase_cell(cell)
		_sync_overlay()


func clear_turret_target_after(cell: Vector2i, delay_sec: float) -> void:
	get_tree().create_timer(delay_sec).timeout.connect(func() -> void:
		clear_turret_target(cell)
	)


func set_radar_ping_cells(cells: Array[Vector2i]) -> void:
	_radar_cells = cells.duplicate()
	_sync_overlay()


func highlight_cell_color(cell: Vector2i, color_type: String) -> void:
	set_turret_target(cell, "lock" if color_type == "yellow" else "fire")


func is_walkable(cell: Vector2i, ignore_id: StringName = &"") -> bool:
	if not is_in_bounds(cell) or is_wall(cell):
		return false
	return not GameState.is_cell_occupied(cell, ignore_id)


func is_wall(cell: Vector2i) -> bool:
	if not is_in_bounds(cell):
		return true
	var atlas := ground_layer.get_cell_atlas_coords(cell)
	return atlas == TILE_WALL


func is_in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < grid_width and cell.y >= 0 and cell.y < grid_height


func get_walkable_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for x in range(grid_width):
		for y in range(grid_height):
			var cell := Vector2i(x, y)
			if not is_wall(cell):
				cells.append(cell)
	return cells


func clear_all_entities() -> void:
	if entities_layer == null:
		return
	for child in entities_layer.get_children():
		child.queue_free()


func place_entity(node: Node2D, cell: Vector2i) -> void:
	if entities_layer == null:
		push_error("GridManager.place_entity: Entities layer chưa sẵn sàng.")
		return
	if not is_in_bounds(cell):
		push_warning("GridManager.place_entity: ô ngoài map %s" % cell)
		return
	if node.has_method("set_cell"):
		node.call("set_cell", cell)
	var world_pos := cell_to_local_center(cell)
	entities_layer.add_child(node)
	node.position = world_pos
	node.z_index = 4


func snap_all_entities() -> void:
	if entities_layer == null:
		return
	for child in entities_layer.get_children():
		if child is Node2D:
			var n := child as Node2D
			var cell := local_to_cell(n.position)
			if cell == Vector2i(-1, -1):
				continue
			n.position = cell_to_local_center(cell)


func _sync_overlay() -> void:
	if grid_overlay and grid_overlay.has_method("set_turret_marks"):
		grid_overlay.call("set_turret_marks", _turret_marks)
	if grid_overlay and grid_overlay.has_method("set_radar_cells"):
		grid_overlay.call("set_radar_cells", _radar_cells)


func _on_entity_moved(entity_id: StringName, _from: Vector2i, to: Vector2i) -> void:
	clear_move_highlights()
	if TurnManager.current_phase == TurnManager.Phase.PLAYER and entity_id == &"player":
		highlight_player_moves(to)
