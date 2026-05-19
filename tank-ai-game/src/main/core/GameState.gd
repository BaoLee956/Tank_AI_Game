################################################################################
# GameState.gd — Autoload / Singleton toàn cục
#
# ĐĂNG KÝ AUTOLOAD: Project → Project Settings → Autoload
# Tên: "GameState", Path: res://GameState.gd
# KHÔNG dùng class_name ở đây vì Autoload đã tạo tên global tự động.
################################################################################

extends Node
# KHÔNG đặt class_name GameState ở đây — Autoload tự tạo tên toàn cục rồi.

# ═══════════════════════════════════════════════════════════════════════════════
# SIGNALS
# ═══════════════════════════════════════════════════════════════════════════════

signal bullets_changed(new_count: int)
signal entity_moved(entity_id: StringName, from_cell: Vector2i, to_cell: Vector2i)
signal entity_stunned(entity: Node, duration_turns: int)
signal entity_stun_expired(entity: Node)
signal game_over(reason: String)
signal game_won()

# ═══════════════════════════════════════════════════════════════════════════════
# HẰNG SỐ
# ═══════════════════════════════════════════════════════════════════════════════

const STARTING_BULLETS: int = 2
const MAX_BULLETS_STORED: int = 3
const BULLET_REWARD_INTERVAL: int = 3
const BULLET_DAMAGE: int = 50
const MINE_DAMAGE: int = 100
const EMP_STUN_TURNS: int = 1

# ═══════════════════════════════════════════════════════════════════════════════
# TRẠNG THÁI GAME
# ═══════════════════════════════════════════════════════════════════════════════

var bullet_count: int = STARTING_BULLETS
var current_turn: int = 0
var is_game_active: bool = false

var entity_positions: Dictionary = {}
var stunned_entities: Dictionary = {}

var player_ref: Node = null
var hunter_ref: Node = null
var turrets: Array = []
var enemy_base_ref: Node = null
var traps: Array = []
var win_reason: String = ""

# ═══════════════════════════════════════════════════════════════════════════════
# KHỞI TẠO
# ═══════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	pass


# ═══════════════════════════════════════════════════════════════════════════════
# QUẢN LÝ PHIÊN CHƠI
# ═══════════════════════════════════════════════════════════════════════════════

func register_trap(trap_node: Node) -> void:
	traps.append(trap_node)
	trap_node.tree_exited.connect(_on_trap_exited.bind(trap_node))

func _on_trap_exited(trap_node: Node) -> void:
	traps.erase(trap_node)

func reset_session() -> void:
	bullet_count = STARTING_BULLETS
	current_turn = 0
	is_game_active = true
	entity_positions.clear()
	stunned_entities.clear()
	player_ref = null
	hunter_ref = null
	turrets.clear()
	enemy_base_ref = null
	traps.clear()
	emit_signal("bullets_changed", bullet_count)


func prepare_for_restart() -> void:
	is_game_active = false
	prune_stale_references()
	player_ref = null
	hunter_ref = null
	enemy_base_ref = null
	turrets.clear()
	traps.clear()
	entity_positions.clear()
	stunned_entities.clear()


func prune_stale_references() -> void:
	var live_turrets: Array = []
	for t in turrets:
		if is_instance_valid(t):
			live_turrets.append(t)
	turrets = live_turrets
	var live_traps: Array = []
	for trap in traps:
		if is_instance_valid(trap):
			live_traps.append(trap)
	traps = live_traps
	if player_ref != null and not is_instance_valid(player_ref):
		player_ref = null
	if hunter_ref != null and not is_instance_valid(hunter_ref):
		hunter_ref = null
	if enemy_base_ref != null and not is_instance_valid(enemy_base_ref):
		enemy_base_ref = null


func try_reward_bullet_on_turn(turn_number: int) -> void:
	if turn_number <= 0 or turn_number % BULLET_REWARD_INTERVAL != 0:
		return
	add_bullet()


func add_bullet() -> void:
	if bullet_count >= MAX_BULLETS_STORED:
		return
	bullet_count += 1
	emit_signal("bullets_changed", bullet_count)


func is_turret_cell(cell: Vector2i) -> bool:
	prune_stale_references()
	for turret in turrets:
		if not is_instance_valid(turret):
			continue
		if turret is Turret:
			var tid: StringName = (turret as Turret).get_entity_id()
			if get_entity_cell(tid) == cell:
				return true
	return false

func save_checkpoint() -> void:
	pass

func load_checkpoint() -> void:
	pass


# ═══════════════════════════════════════════════════════════════════════════════
# QUẢN LÝ ĐẠN
# ═══════════════════════════════════════════════════════════════════════════════

func has_bullets() -> bool:
	return bullet_count > 0

func consume_bullet() -> bool:
	if not has_bullets():
		return false
	bullet_count -= 1
	emit_signal("bullets_changed", bullet_count)
	return true


# ═══════════════════════════════════════════════════════════════════════════════
# QUẢN LÝ VỊ TRÍ THỰC THỂ
# ═══════════════════════════════════════════════════════════════════════════════

func register_entity(entity_id: StringName, cell: Vector2i, node: Node = null) -> void:
	entity_positions[entity_id] = cell
	if node:
		node.tree_exited.connect(_on_entity_tree_exited.bind(entity_id, node))

func _on_entity_tree_exited(entity_id: StringName, node: Node) -> void:
	entity_positions.erase(entity_id)
	if stunned_entities.has(node):
		stunned_entities.erase(node)

func unregister_entity(entity_id: StringName) -> void:
	entity_positions.erase(entity_id)

func move_entity(entity_id: StringName, new_cell: Vector2i) -> void:
	var old_cell: Vector2i = entity_positions.get(entity_id, Vector2i(-1, -1))
	entity_positions[entity_id] = new_cell
	emit_signal("entity_moved", entity_id, old_cell, new_cell)

func get_entity_cell(entity_id: StringName) -> Vector2i:
	return entity_positions.get(entity_id, Vector2i(-1, -1))

func is_cell_occupied(cell: Vector2i, ignore_id: StringName = &"") -> bool:
	if is_turret_cell(cell):
		return true
	for id: StringName in entity_positions:
		if id == ignore_id:
			continue
		if entity_positions[id] != cell:
			continue
		if ignore_id == &"player" and id == &"enemy_base":
			continue
		return true
	return false


# ═══════════════════════════════════════════════════════════════════════════════
# HỆ THỐNG STUN
# ═══════════════════════════════════════════════════════════════════════════════

func apply_stun(entity: Node, turns: int = EMP_STUN_TURNS) -> void:
	var current: int = stunned_entities.get(entity, 0)
	stunned_entities[entity] = current + turns
	emit_signal("entity_stunned", entity, stunned_entities[entity])

func is_stunned(entity: Node) -> bool:
	return stunned_entities.has(entity) and stunned_entities[entity] > 0

func tick_stuns() -> void:
	var to_remove: Array = []
	for entity in stunned_entities.keys():
		stunned_entities[entity] -= 1
		if stunned_entities[entity] <= 0:
			to_remove.append(entity)
	for entity in to_remove:
		stunned_entities.erase(entity)
		emit_signal("entity_stun_expired", entity)


# ═══════════════════════════════════════════════════════════════════════════════
# THẮNG / THUA
# ═══════════════════════════════════════════════════════════════════════════════

func trigger_game_won() -> void:
	trigger_game_won_with_reason("base_destroyed")

func trigger_game_won_with_reason(reason: String) -> void:
	if not is_game_active:
		return
	is_game_active = false
	win_reason = reason
	emit_signal("game_won")

func trigger_game_over(reason: String = "Game Over") -> void:
	if not is_game_active:
		return
	is_game_active = false
	emit_signal("game_over", reason)
