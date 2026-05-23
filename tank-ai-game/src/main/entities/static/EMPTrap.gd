################################################################################
# EMPTrap.gd — Bẫy EMP
#
# CHỨC NĂNG:
#   • Khi Player hoặc Hunter bước vào vùng Area2D → kích hoạt xung EMP.
#   • Áp Stun lên entity bị dính trong `EMP_STUN_TURNS` lượt qua GameState.
#   • Yêu cầu Member 2 phát hiệu ứng nhiễu sóng điện từ (GPUParticles2D).
#   • Bẫy chỉ kích hoạt một lần rồi bị vô hiệu hoá.
#
# NGƯỜI PHỤ TRÁCH:
#   [Thành viên 3 (Game Master, Core Logic & System)] — Logic
#   [Thành viên 2 (UI, VFX & TileMap)] — VFX
################################################################################

extends Area2D
class_name EMPTrap

signal emp_triggered(trap_position: Vector2) # → Member 2 phát hiệu ứng

## True sau lần kích hoạt đầu tiên.
var _triggered: bool = false

## Tham chiếu ParticleManager (Member 2) — gán qua Inspector hoặc autoload.
@export var particle_manager_path: NodePath
var _particle_mgr: ParticleManager = null


func set_cell(cell: Vector2i) -> void:
	# Tính toán vị trí pixel tương tự như Player
	position = Vector2(cell.x * 32 + 16, cell.y * 32 + 16)


func _hide_visual() -> void:
	var spr := get_node_or_null("Sprite2D") as Sprite2D
	if spr:
		spr.visible = false


func _ready() -> void:
	_hide_visual()
	GameState.register_trap(self )
	body_entered.connect(_on_body_entered)
	if not particle_manager_path.is_empty():
		_particle_mgr = get_node(particle_manager_path) as ParticleManager


## Gọi thủ công để "nạp" bẫy lại (nếu cần thiết kế reset).
func arm() -> void:
	_triggered = false
	$CollisionShape2D.disabled = false


## Xung EMP lan ra vùng ảnh hưởng (tất cả body trong Area2D lúc trigger).
func activate_pulse() -> void:
	if _triggered:
		return
	_triggered = true
	$CollisionShape2D.disabled = true # Vô hiệu hoá để không trigger lại.

	emit_signal("emp_triggered", global_position)

	# Kích hoạt VFX (Member 2).
	if _particle_mgr != null:
		_particle_mgr.play_effect_at(&"emp_pulse", global_position)

	# Áp stun lên tất cả overlapping bodies lúc kích hoạt.
	for body: Node2D in get_overlapping_bodies():
		apply_emp_effect(body)


## Áp stun lên một entity cụ thể.
func apply_emp_effect(target: Node) -> void:
	if target is Player or target is Hunter or target is Turret:
		GameState.apply_stun(target, GameState.EMP_STUN_TURNS)


func _on_body_entered(body: Node2D) -> void:
	if _triggered:
		return
	# Chỉ kích hoạt khi Player hoặc Hunter giẫm lên.
	if body is Player or body is Hunter:
		activate_pulse()
