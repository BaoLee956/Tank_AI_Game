################################################################################
# ParticleManager.gd — Pool và spawn hiệu ứng hạt (VFX)
#
# CHỨC NĂNG:
#   • Quản lý pool GPUParticles2D để tái sử dụng, tránh tạo/hủy liên tục.
#   • Cung cấp API đơn giản: play_effect_at(id, pos) cho tất cả hệ thống khác.
#   • Hỗ trợ các effect ID chuẩn: "explosion", "emp_pulse", "turret_lock".
#
# CÁCH SỬ DỤNG:
#   # Từ bất kỳ node nào (sau khi gán reference hoặc dùng autoload):
#   ParticleManager.play_effect_at(&"explosion", global_position)
#
# NODE SETUP:
#   Trong scene, thêm các GPUParticles2D làm con của ParticleManager:
#     - ExplosionParticle (one_shot = true, emitting = false)
#     - EmpParticle       (one_shot = true, emitting = false)
#     - LockParticle      (one_shot = true, emitting = false)
#   Gán chúng vào exported vars bên dưới.
#
# NGƯỜI PHỤ TRÁCH:
#   [Thành viên 2 (UI, VFX & TileMap)]
################################################################################

extends Node2D
class_name ParticleManager

@export var explosion_scene: PackedScene
@export var emp_scene: PackedScene
@export var lock_scene: PackedScene

const POOL_SIZE: int = 4

## effect_id → Array[GPUParticles2D]
var _pools: Dictionary = {}
## effect_id → PackedScene
var _scene_map: Dictionary = {}
## GPUParticles2D instance → effect_id (để tìm pool khi recycle)
var _instance_to_id: Dictionary = {}


func _ready() -> void:
	_register_effect(&"explosion", explosion_scene)
	_register_effect(&"emp_pulse", emp_scene)
	_register_effect(&"turret_lock", lock_scene)


func _register_effect(effect_id: StringName, scene: PackedScene) -> void:
	if scene == null:
		push_warning("ParticleManager: scene cho '%s' chưa được gán." % effect_id)
		return
	_scene_map[effect_id] = scene
	_pools[effect_id] = []
	for _i in range(POOL_SIZE):
		var inst: GPUParticles2D = scene.instantiate() as GPUParticles2D
		inst.emitting = false
		inst.one_shot = true
		add_child(inst)
		# FIX: lưu ánh xạ instance → effect_id để recycle đúng pool
		_instance_to_id[inst] = effect_id
		inst.finished.connect(_on_particle_finished.bind(inst))
		_pools[effect_id].append(inst)


func play_effect_at(effect_id: StringName, world_position: Vector2) -> void:
	if not _pools.has(effect_id):
		push_warning("ParticleManager: không tìm thấy effect '%s'." % effect_id)
		return

	var pool: Array = _pools[effect_id]

	if pool.is_empty():
		# Pool cạn: tạo instance mới
		var scene: PackedScene = _scene_map.get(effect_id)
		if scene == null:
			return
		var inst: GPUParticles2D = scene.instantiate() as GPUParticles2D
		inst.one_shot = true
		add_child(inst)
		_instance_to_id[inst] = effect_id
		inst.finished.connect(_on_particle_finished.bind(inst))
		pool.append(inst)

	var particle: GPUParticles2D = pool.pop_back() as GPUParticles2D
	particle.global_position = world_position
	particle.emitting = true


## FIX: dùng _instance_to_id để tìm đúng pool thay vì so sánh process_material
func _on_particle_finished(instance: GPUParticles2D) -> void:
	if instance == null:
		return
	instance.emitting = false
	instance.global_position = Vector2(-9999.0, -9999.0)

	var effect_id: StringName = _instance_to_id.get(instance, &"")
	if effect_id != &"" and _pools.has(effect_id):
		_pools[effect_id].append(instance)


## Alias cũ (để tương thích nếu nơi nào đó gọi recycle_effect trực tiếp)
func recycle_effect(instance: Node) -> void:
	if instance is GPUParticles2D:
		_on_particle_finished(instance as GPUParticles2D)