extends Node

@onready var map_gen: MapGenerator = $MapGenerator
@onready var grid: GridManager = $GridManager
@onready var player_input: PlayerInput = $PlayerInput
@onready var hud: HUDControl = $HUD/HUDControl
@onready var camera: Camera2D = $Camera2D
@onready var background: ColorRect = $Background
@onready var astar: AStarHunter = $AStarHunter
@onready var auto_radar: Node = $AutoRadar

const GRID_SCALE: float = 1.65


func _ready() -> void:
	TurnManager.reset_turn_system()
	_setup_display()
	GameState.reset_session()
	if auto_radar:
		auto_radar.assign_grid(grid)
	call_deferred("_boot_game")


func _boot_game() -> void:
	map_gen.generate_map(randi())
	_center_grid()

	var hunter: Hunter = GameState.hunter_ref as Hunter if is_instance_valid(GameState.hunter_ref) else null
	if hunter:
		hunter.astar_hunter_path = hunter.get_path_to(astar)
		hunter.bind_astar(astar)

	var player: Player = GameState.player_ref as Player if is_instance_valid(GameState.player_ref) else null
	if player == null:
		push_error("Main: không tìm thấy Player sau khi sinh bản đồ.")
		return

	player_input.move_requested.connect(_on_move_requested)
	player_input.shoot_requested.connect(_on_shoot_requested)
	player.action_animation_finished.connect(_on_player_action_finished)
	TurnManager.player_turn_started.connect(_on_player_turn_started)
	TurnManager.player_turn_ended.connect(_on_player_turn_ended)
	TurnManager.turret_phase_started.connect(_on_turret_phase_started)
	TurnManager.hunter_phase_started.connect(_on_hunter_phase_started)
	hud.connect_player(player)
	hud.tutorial_finished.connect(_on_tutorial_finished)
	hud.setup_restart(self)
	if not player.player_died.is_connected(_on_player_died):
		player.player_died.connect(_on_player_died)
	get_viewport().size_changed.connect(_on_viewport_resized)
	call_deferred("_center_grid")


func _on_tutorial_finished() -> void:
	TurnManager.start_turn()


func _on_player_died() -> void:
	var shake := create_tween()
	shake.set_trans(Tween.TRANS_SINE)
	shake.tween_property(camera, "offset", Vector2(8, -6), 0.05)
	shake.tween_property(camera, "offset", Vector2(-10, 4), 0.05)
	shake.tween_property(camera, "offset", Vector2(6, 2), 0.05)
	shake.tween_property(camera, "offset", Vector2.ZERO, 0.08)


func _setup_display() -> void:
	background.color = Color(0.08, 0.1, 0.14)
	grid.scale = Vector2(GRID_SCALE, GRID_SCALE)
	camera.enabled = true
	camera.position_smoothing_enabled = true


func _on_viewport_resized() -> void:
	_center_grid()


func _center_grid() -> void:
	var ts := grid.tile_size
	var base_pixel := Vector2(grid.grid_width * ts.x, grid.grid_height * ts.y)
	var vp := get_viewport().get_visible_rect().size
	var insets := hud.get_play_area_insets() if hud else Vector2i(84, 68)
	var margin_top := float(insets.x)
	var margin_bottom := float(insets.y)
	var play_h := maxf(120.0, vp.y - margin_top - margin_bottom)
	var play_w := vp.x
	var scale_factor := GRID_SCALE
	var scaled := base_pixel * scale_factor
	if scaled.x > play_w or scaled.y > play_h:
		scale_factor = minf(play_w / base_pixel.x, play_h / base_pixel.y) * 0.96
	grid.scale = Vector2(scale_factor, scale_factor)
	var pixel := base_pixel * scale_factor
	grid.position = Vector2(
		(play_w - pixel.x) * 0.5,
		margin_top + (play_h - pixel.y) * 0.5
	)
	camera.position = grid.position + pixel * 0.5


func _on_move_requested(target_cell: Vector2i) -> void:
	if not is_instance_valid(GameState.player_ref):
		player_input.set_action_allowed(true)
		return
	var player := GameState.player_ref as Player
	if not player.apply_move_intent(target_cell):
		player_input.set_action_allowed(true)
		hud.show_hint("Không thể di chuyển tới ô này.")


func _on_shoot_requested(target_cell: Vector2i) -> void:
	if not is_instance_valid(GameState.player_ref):
		player_input.set_action_allowed(true)
		return
	var player := GameState.player_ref as Player
	if player.shoot_at(target_cell):
		_end_player_action_after_delay(0.15)
	else:
		player_input.set_action_allowed(true)
		hud.show_hint("Bắn không hợp lệ (Hunter: chỉ bắn cách 2 ô thẳng hàng; ô kề khác: mìn/pháo).")


func _on_player_action_finished() -> void:
	_end_player_action()


func _end_player_action_after_delay(sec: float) -> void:
	await get_tree().create_timer(sec).timeout
	_end_player_action()


func _end_player_action() -> void:
	if TurnManager.current_phase != TurnManager.Phase.PLAYER:
		return
	if not GameState.is_game_active:
		return
	TurnManager.end_player_turn()


func _on_player_turn_started() -> void:
	if is_instance_valid(GameState.player_ref) and GameState.is_stunned(GameState.player_ref):
		hud.show_hint("Bạn bị choáng — mất lượt này.")
		call_deferred("_skip_stunned_turn")
		return
	var player := GameState.player_ref as Player if is_instance_valid(GameState.player_ref) else null
	if player:
		grid.highlight_player_moves(player.get_cell())
	hud.set_phase_text("Lượt người chơi")
	var turns_to_ammo := GameState.BULLET_REWARD_INTERVAL - (GameState.current_turn % GameState.BULLET_REWARD_INTERVAL)
	if turns_to_ammo == GameState.BULLET_REWARD_INTERVAL:
		turns_to_ammo = 0
	var ammo_hint := ""
	if turns_to_ammo > 0:
		ammo_hint = " | +1 đạn sau %d lượt" % turns_to_ammo
	hud.show_hint(
		"Radar: vòng xanh trên ô đi được = có bẫy/Hunter ẩn.%s" % ammo_hint
	)


func _skip_stunned_turn() -> void:
	if TurnManager.current_phase == TurnManager.Phase.PLAYER:
		_end_player_action()


func _on_player_turn_ended() -> void:
	grid.clear_move_highlights()
	hud.set_phase_text("Pha AI...")


func _on_hunter_phase_started() -> void:
	hud.set_phase_text("Hunter di chuyển")
	hud.show_hint("Hunter đuổi 1 ô; nếu kề bạn sau khi đi sẽ bắn. Không còn đường lui = thua.")


func restart_game() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Main.tscn")


func _on_turret_phase_started() -> void:
	GameState.prune_stale_references()
	var will_fire := false
	for t in GameState.turrets:
		if not is_instance_valid(t) or not t is Turret:
			continue
		if (t as Turret).has_pending_shot():
			will_fire = true
			break
	if not will_fire:
		hud.set_phase_text("Pháo: NGẮM (ô vàng)")
		hud.show_hint("Pháo đang khóa mục tiêu — tránh ô vàng, lượt sau sẽ bắn đỏ.")
	else:
		hud.set_phase_text("Pháo: BẮN (ô đỏ)")
		hud.show_hint("Pháo đang bắn! Đứng trên ô đỏ = chết. Dụ Hunter vào ô đỏ để thắng.")
