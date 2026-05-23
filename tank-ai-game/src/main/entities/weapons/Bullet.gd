################################################################################
# Bullet.gd — Đạn bay
#
# CHỨC NĂNG:
#   • Di chuyển theo hướng cố định với vận tốc đã set qua launch().
#   • Gây sát thương khi va chạm với Player / EnemyBase.
#   • Tự hủy khi hết range hoặc va chạm.
#
# NGƯỜI PHỤ TRÁCH:
#   [Thành viên 3 (Game Master, Core Logic & System)]
################################################################################

extends Area2D
class_name Bullet

## Sát thương gây ra khi trúng đích.
@export var damage: int = GameState.BULLET_DAMAGE

# CHÈN THÊM DÒNG NÀY:
var shooter: Node2D = null

## Tốc độ pixel/giây (được ghi đè bởi launch()).
var _velocity: Vector2 = Vector2.ZERO

## Tổng quãng đường tối đa trước khi tự hủy (px).
var max_range: float = 512.0
var _traveled: float = 0.0


func _ready() -> void:
	# Kết nối signal va chạm của Area2D.
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	position += _velocity * delta
	_traveled += _velocity.length() * delta
	
	if _traveled >= max_range:
		# Gọi hiệu ứng nổ tại vị trí đích
		var particle_mgr = get_node_or_null("/root/ParticleManager")
		if particle_mgr:
			particle_mgr.play_effect_at(&"explosion", global_position)
		queue_free() # Tự hủy


## Đặt vận tốc và bắt đầu bay.
func launch(velocity: Vector2) -> void:
	_velocity = velocity
	# Xoay sprite theo hướng bay.
	rotation = velocity.angle()


func _on_body_entered(body: Node2D) -> void:
	if shooter != null and body == shooter:
		return

	if body is Player:
		(body as Player).take_damage(damage)
	elif body is EnemyBase:
		(body as EnemyBase).register_hit(damage)
		
	var particle_mgr = get_node_or_null("/root/ParticleManager")
	if particle_mgr:
		particle_mgr.play_effect_at(&"explosion", global_position)
		
	# THÊM DÒNG NÀY ĐỂ DEBUG XEM NÓ ĐỤNG CÁI GÌ:
	print("VIÊN ĐẠN VỪA ĐỤNG TRÚNG: ", body.name) 
	
	queue_free()