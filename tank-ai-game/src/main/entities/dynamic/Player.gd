extends Node2D
class_name Player

signal move_animation_requested(from_pos: Vector2, to_pos: Vector2)
signal action_animation_finished()
signal health_changed(new_hp: int, max_hp: int)
signal player_died()

const MAX_HP: int = 100
const ENTITY_ID: StringName = &"player"
const MOVE_DURATION: float = 0.22

var _hp: int = MAX_HP
var _cell: Vector2i = Vector2i(0, 0)
var _cell_from_spawn: bool = false
var _is_animating: bool = false

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D


func set_cell(cell: Vector2i) -> void:
	_cell = cell
	_cell_from_spawn = true


func _ready() -> void:
	if not _cell_from_spawn:
		_cell = _pixel_to_cell(position)
	GameState.player_ref = self
	GameState.register_entity(ENTITY_ID, _cell)
	TurnManager.player_turn_ended.connect(_on_player_turn_ended)


func is_animating() -> bool:
	return _is_animating


func apply_move_intent(target_cell: Vector2i) -> bool:
	if _is_animating or GameState.is_stunned(self):
		return false
	if not _is_cell_reachable(target_cell):
		return false

	var grid := _get_grid()
	var target_pos: Vector2
	if grid:
		target_pos = grid.cell_to_local_center(target_cell)
	else:
		target_pos = _cell_to_pixel(target_cell)

	var from_pos := position
	_cell = target_cell
	GameState.move_entity(ENTITY_ID, _cell)

	_is_animating = true
	if sprite:
		var dir := target_pos - from_pos
		if abs(dir.x) >= abs(dir.y):
			sprite.flip_h = dir.x < 0

	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "position", target_pos, MOVE_DURATION)
	tween.finished.connect(_on_move_tween_done.bind(from_pos, target_pos))

	return true


func _on_move_tween_done(from_pos: Vector2, to_pos: Vector2) -> void:
	_is_animating = false
	emit_signal("move_animation_requested", from_pos, to_pos)
	_check_tile_after_move()
	action_animation_finished.emit()


func _check_tile_after_move() -> void:
	var grid := _get_grid()
	if grid == null:
		return
	if GameState.get_entity_cell(&"enemy_base") == _cell:
		GameState.trigger_game_won_with_reason("base_captured")
		return
	for trap in GameState.traps:
		if trap is MineTrap:
			var trap_cell := grid.local_center_to_cell((trap as Node2D).position)
			if trap_cell == _cell:
				(trap as MineTrap).trigger(self)
				return
		if trap is EMPTrap:
			var trap_cell := grid.local_center_to_cell((trap as Node2D).position)
			if trap_cell == _cell:
				(trap as EMPTrap).activate_pulse()
				return


func take_damage(amount: int, death_reason: String = "") -> void:
	if amount <= 0:
		return
	_hp = maxi(0, _hp - amount)
	emit_signal("health_changed", _hp, MAX_HP)
	if _hp == 0:
		_on_death(death_reason)


func get_cell() -> Vector2i:
	return _cell

func get_hp() -> int:
	return _hp


func shoot_at(target_cell: Vector2i) -> bool:
	if _is_animating or GameState.is_stunned(self):
		return false
	if not GameState.has_bullets():
		return false

	var dist: int = _shoot_distance(target_cell)
	if dist < 1 or dist > 2:
		return false
	if dist == 2 and not _has_clear_shot(target_cell):
		return false

	var target: Node2D = _get_entity_at(target_cell)
	if dist == 2:
		if is_instance_valid(target) and target is Hunter:
			GameState.apply_stun(target, 2)
			GameState.consume_bullet()
			_play_shoot_feedback(target_cell)
			return true
		return false

	if target == null:
		GameState.consume_bullet()
		_play_shoot_feedback(target_cell)
		return true

	if target is MineTrap:
		target.queue_free()
		GameState.consume_bullet()
	elif target is EMPTrap:
		target.queue_free()
		GameState.consume_bullet()
	elif target is Hunter:
		return false
	elif target is Turret:
		if not is_instance_valid(target):
			return false
		var t := target as Turret
		GameState.turrets.erase(t)
		GameState.unregister_entity(t.get_entity_id())
		t.queue_free()
		GameState.consume_bullet()
	elif target is EnemyBase:
		return false
	else:
		return false
	_play_shoot_feedback(target_cell)
	return true


func _play_shoot_feedback(target_cell: Vector2i) -> void:
	var grid := _get_grid()
	if grid == null or sprite == null:
		return
	var target_pos := grid.cell_to_local_center(target_cell)
	var dir := target_pos - position
	if abs(dir.x) >= abs(dir.y):
		sprite.flip_h = dir.x < 0
	var tween := create_tween()
	tween.tween_property(sprite, "scale", sprite.scale * 1.15, 0.06)
	tween.tween_property(sprite, "scale", Vector2(0.4, 0.4), 0.08)


func _get_entity_at(cell: Vector2i) -> Node2D:
	if is_instance_valid(GameState.player_ref) and GameState.get_entity_cell(&"player") == cell:
		return GameState.player_ref as Node2D
	if is_instance_valid(GameState.hunter_ref) and GameState.get_entity_cell(&"hunter") == cell:
		return GameState.hunter_ref as Node2D
	if is_instance_valid(GameState.enemy_base_ref) and GameState.get_entity_cell(&"enemy_base") == cell:
		return GameState.enemy_base_ref as Node2D
	GameState.prune_stale_references()
	for turret in GameState.turrets:
		if not is_instance_valid(turret) or not turret is Turret:
			continue
		var t := turret as Turret
		if GameState.get_entity_cell(t.get_entity_id()) == cell:
			return t
	var grid := _get_grid()
	if grid:
		for trap in GameState.traps:
			if is_instance_valid(trap) and trap is Node2D:
				var trap_cell := grid.local_center_to_cell((trap as Node2D).position)
				if trap_cell == cell:
					return trap as Node2D
	return null


func _shoot_distance(target_cell: Vector2i) -> int:
	var diff: Vector2i = target_cell - _cell
	return absi(diff.x) + absi(diff.y)


func _has_clear_shot(target_cell: Vector2i) -> bool:
	var diff: Vector2i = target_cell - _cell
	if diff.x != 0 and diff.y != 0:
		return false
	var grid := _get_grid()
	if grid == null:
		return false
	var mid: Vector2i = (_cell + target_cell) / 2
	if grid.is_wall(mid):
		return false
	return true


func _is_cell_reachable(target: Vector2i) -> bool:
	var diff: Vector2i = target - _cell
	if abs(diff.x) + abs(diff.y) != 1:
		return false
	var grid := _get_grid()
	if grid == null:
		return false
	return grid.is_walkable(target, ENTITY_ID)


func _get_grid() -> GridManager:
	var p := get_parent()
	if p and p.name == "Entities":
		return p.get_parent() as GridManager
	return get_node_or_null("/root/Main/GridManager") as GridManager


func _on_death(reason: String = "") -> void:
	emit_signal("player_died")
	GameState.unregister_entity(ENTITY_ID)
	var msg := reason if not reason.is_empty() else "Xe tăng bị tiêu diệt!"
	GameState.trigger_game_over(msg)


func _on_player_turn_ended() -> void:
	pass


func _cell_to_pixel(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * 32 + 16, cell.y * 32 + 16)

func _pixel_to_cell(pixel: Vector2) -> Vector2i:
	return Vector2i(int(pixel.x / 32), int(pixel.y / 32))
