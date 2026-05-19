################################################################################
# EnemyBase.gd — Căn cứ địch (mục tiêu thắng)
#
# CHỨC NĂNG:
#   • Có HP, nhận sát thương từ Bullet của Player.
#   • Khi HP về 0 → kích hoạt GameState.trigger_game_won().
#   • Phát signal để Member 2 hiển thị hiệu ứng phá hủy.
#
# NGƯỜI PHỤ TRÁCH:
#   [Thành viên 3 (Game Master, Core Logic & System)]
################################################################################

extends Area2D
class_name EnemyBase

signal base_damaged(remaining_hp: int, max_hp: int)
signal base_destroyed()

const ENTITY_ID: StringName = &"enemy_base"

@export var max_health: int = 100
var _health: int = max_health
var _cell: Vector2i = Vector2i.ZERO
var _cell_from_spawn: bool = false

@export var particle_manager_path: NodePath
var _particle_mgr: ParticleManager = null


func set_cell(cell: Vector2i) -> void:
	_cell = cell
	_cell_from_spawn = true


func _ready() -> void:
	_health = max_health
	GameState.enemy_base_ref = self
	if not _cell_from_spawn:
		var grid := get_node_or_null("/root/Main/GridManager") as GridManager
		if grid:
			_cell = grid.world_to_cell(global_position)
	GameState.register_entity(ENTITY_ID, _cell, self)
	body_entered.connect(_on_body_entered)
	if not particle_manager_path.is_empty():
		_particle_mgr = get_node(particle_manager_path) as ParticleManager


## Nhận sát thương từ Bullet.
func register_hit(damage: int) -> void:
	if damage <= 0:
		return
	_health = maxi(0, _health - damage)
	emit_signal("base_damaged", _health, max_health)

	if _particle_mgr != null:
		_particle_mgr.play_effect_at(&"explosion", global_position)

	if is_destroyed():
		emit_signal("base_destroyed")
		GameState.trigger_game_won()
		queue_free()


func is_destroyed() -> bool:
	return _health <= 0


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		GameState.trigger_game_won_with_reason("base_captured")