extends Node2D
class_name Turret

signal target_locked(target_cell: Vector2i)
signal fired(target_cell: Vector2i)

@export var attack_range: int = 4
var _aim_cell: Vector2i = Vector2i(-1, -1)
var _cell: Vector2i
var _entity_id: StringName

const TILE_SIZE: int = 32
const FIRE_DISPLAY_SEC: float = 0.55

var _cell_from_spawn: bool = false


func set_cell(cell: Vector2i) -> void:
	_cell = cell
	_cell_from_spawn = true
	_entity_id = StringName("turret_%d_%d" % [_cell.x, _cell.y])


func has_pending_shot() -> bool:
	return _aim_cell != Vector2i(-1, -1)


func get_aim_cell() -> Vector2i:
	return _aim_cell


func get_entity_id() -> StringName:
	return _entity_id


func _ready() -> void:
	if not _cell_from_spawn:
		_cell = _pixel_to_cell(position)
		_entity_id = StringName("turret_%d_%d" % [_cell.x, _cell.y])
	GameState.register_entity(_entity_id, _cell, self)
	GameState.turrets.append(self)
	TurnManager.turret_phase_started.connect(_on_turret_phase)


func _on_turret_phase() -> void:
	if GameState.is_stunned(self):
		TurnManager.report_turret_done()
		return

	var grid := _get_grid()
	if grid == null:
		TurnManager.report_turret_done()
		return

	if _aim_cell == Vector2i(-1, -1):
		_begin_aim(grid)
	else:
		_execute_shot(grid)

	TurnManager.report_turret_done()


func _begin_aim(grid: GridManager) -> void:
	_aim_cell = _pick_lock_cell(grid)
	grid.set_turret_target(_aim_cell, "lock")
	emit_signal("target_locked", _aim_cell)


func _execute_shot(grid: GridManager) -> void:
	var fired_at := _aim_cell
	grid.set_turret_target(fired_at, "fire")

	var target_node: Node2D = _get_entity_at(fired_at)
	if target_node:
		if target_node is Player:
			(target_node as Player).take_damage(1000, "Bạn bị pháo tiêu diệt!")
		elif target_node is Hunter:
			GameState.trigger_game_won_with_reason("hunter_lured")

	emit_signal("fired", fired_at)
	grid.clear_turret_target_after(fired_at, FIRE_DISPLAY_SEC)
	_aim_cell = Vector2i(-1, -1)


func _get_grid() -> GridManager:
	var p := get_parent()
	if p and p.name == "Entities":
		return p.get_parent() as GridManager
	return get_node_or_null("/root/Main/GridManager") as GridManager


func _pick_lock_cell(grid: GridManager) -> Vector2i:
	var candidates: Array[Vector2i] = []
	for x in range(grid.grid_width):
		for y in range(grid.grid_height):
			var c := Vector2i(x, y)
			if grid.is_walkable(c) or GameState.get_entity_cell(&"enemy_base") == c:
				candidates.append(c)
	if candidates.is_empty():
		return Vector2i(randi() % grid.grid_width, randi() % grid.grid_height)
	return candidates[randi() % candidates.size()]


func _get_entity_at(cell: Vector2i) -> Node2D:
	if GameState.player_ref and GameState.get_entity_cell(&"player") == cell:
		return GameState.player_ref
	if GameState.hunter_ref and GameState.get_entity_cell(&"hunter") == cell:
		return GameState.hunter_ref
	return null


func _cell_to_pixel(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * TILE_SIZE + TILE_SIZE / 2, cell.y * TILE_SIZE + TILE_SIZE / 2)


func _pixel_to_cell(pixel: Vector2) -> Vector2i:
	return Vector2i(int(pixel.x / TILE_SIZE), int(pixel.y / TILE_SIZE))
