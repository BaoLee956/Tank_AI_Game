################################################################################
# MineTrap.gd — Bẫy mìn tĩnh
#
# CHỨC NĂNG:
#   • Phát hiện va chạm, gây sát thương ngay lập tức.
#   • Yêu cầu Member 2 phát hiệu ứng nổ.
#   • Bẫy chỉ nổ một lần, sau đó queue_free().
#
# NGƯỜI PHỤ TRÁCH:
#   [Thành viên 3 (Game Master, Core Logic & System)] — Logic
#   [Thành viên 2 (UI, VFX & TileMap)] — VFX
################################################################################

extends Area2D
class_name MineTrap

signal mine_exploded(mine_position: Vector2) # → Member 2 phát hiệu ứng nổ

var _armed: bool = false

@export var particle_manager_path: NodePath
var _particle_mgr: ParticleManager = null


func _ready() -> void:
	_hide_visual()
	GameState.register_trap(self )
	body_entered.connect(_on_body_entered)
	if not particle_manager_path.is_empty():
		_particle_mgr = get_node(particle_manager_path) as ParticleManager
	arm()


## Nạp bẫy — kích hoạt vùng va chạm.
func set_cell(cell: Vector2i) -> void:
	position = Vector2.ZERO


func _hide_visual() -> void:
	var spr := get_node_or_null("Sprite2D") as Sprite2D
	if spr:
		spr.visible = false


func arm() -> void:
	_armed = true
	$CollisionShape2D.disabled = false


## Kích nổ, gây sát thương cho `body`.
func trigger(body: Node2D) -> void:
	if not _armed:
		return
	_armed = false
	$CollisionShape2D.disabled = true

	emit_signal("mine_exploded", global_position)

	# VFX nổ (Member 2).
	if _particle_mgr != null:
		_particle_mgr.play_effect_at(&"explosion", global_position)

	# Gây sát thương.
	if body is Player:
		(body as Player).take_damage(GameState.MINE_DAMAGE, "Bạn dẫm phải bãi mìn!")
	elif body is Hunter:
		# Nếu Hunter dính mìn → optional: có thể kill Hunter hoặc stun.
		GameState.apply_stun(body, 2)

	# Mìn tự hủy sau khi nổ.
	queue_free()


func _on_body_entered(body: Node2D) -> void:
	if _armed:
		trigger(body)
