extends Control
class_name HUDControl

signal tutorial_finished()

@onready var bullet_icon_1: Label = $TopBar/Margin/BulletBar/BulletIcon1
@onready var bullet_icon_2: Label = $TopBar/Margin/BulletBar/BulletIcon2
@onready var bullet_icon_3: Label = $TopBar/Margin/BulletBar/BulletIcon3
@onready var turn_label: Label = $TopBar/Margin/TurnLabel
@onready var phase_label: Label = $TopBar/Margin/PhaseLabel
@onready var hp_label: Label = $TopBar/Margin/HpLabel
@onready var hint_label: Label = $BottomBar/Margin/HintLabel
@onready var result_popup: PanelContainer = $ResultPopup
@onready var result_label: Label = $ResultPopup/Margin/ResultLabel
@onready var result_detail: Label = $ResultPopup/Margin/ResultDetail
@onready var restart_button: Button = $ResultPopup/Margin/RestartButton
@onready var tutorial_popup: PanelContainer = $TutorialPopup
@onready var tutorial_body: Label = $TutorialPopup/Margin/VBox/TutorialBody
@onready var start_button: Button = $TutorialPopup/Margin/VBox/StartButton
@onready var defeat_flash: ColorRect = $DefeatFlash
@onready var top_bar: PanelContainer = $TopBar
@onready var bottom_bar: PanelContainer = $BottomBar

const PLAY_MARGIN_TOP: int = 84
const PLAY_MARGIN_BOTTOM: int = 68

var _hint_timer: float = 0.0
var _last_bullet_count: int = 0
var _restart_host: Node = null

const WIN_TIPS := """Cách chiến thắng:
• A: Dụ Hunter vào ô pháo đang bắn (đỏ).
• B: Bước vào căn cứ địch (góc map) — không cần bắn căn cứ.
• Radar tự quét ô xanh đi được; mỗi 3 lượt +1 đạn (tối đa 3)."""

const TUTORIAL_TEXT := """CYBERTANK: LOGIC BREACH

══ CÁCH CHIẾN THẮNG ══
A) DỤ HUNTER VÀO Ô PHÁO ĐỎ (sau khi pháo ngắm vàng rồi bắn)
B) BƯỚC VÀO CĂN CỨ ĐỊCH (góc map) — chỉ cần di chuyển, không bắn căn cứ

══ ĐIỀU KHIỂN ══
• Trái: di chuyển 1 ô (xanh) | Phải: bắn
• Bắt đầu 2 đạn, tối đa 3 đạn; mỗi 3 lượt hoàn thành +1 đạn
• Bắn Hunter cách 2 ô thẳng hàng (không tường giữa) = choáng 2 lượt

══ RADAR (tự động) ══
• Lấy bạn làm tâm, quét các ô có thể đi
• Vòng xanh = có bẫy hoặc Hunter ẩn trên ô đó

══ MỐI NGUY ══
• Mìn ẩn / EMP | Hunter kề = bị bắn
• Không được đứng trên ô pháo còn hoạt động
• Không còn đường lui = thua

Thứ tự: Bạn → Pháo → Hunter."""


func _ready() -> void:
	result_popup.hide()
	defeat_flash.modulate.a = 0.0
	defeat_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	start_button.pressed.connect(_on_start_pressed)
	_setup_bullet_icons()
	_layout_bars()
	bind_to_game_state()
	show_tutorial()
	resized.connect(_layout_bars)


func _layout_bars() -> void:
	if top_bar:
		top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
		top_bar.offset_left = 0.0
		top_bar.offset_top = 0.0
		top_bar.offset_right = 0.0
		top_bar.offset_bottom = PLAY_MARGIN_TOP
	if bottom_bar:
		bottom_bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		bottom_bar.offset_left = 0.0
		bottom_bar.offset_top = -PLAY_MARGIN_BOTTOM
		bottom_bar.offset_right = 0.0
		bottom_bar.offset_bottom = 0.0


func is_modal_blocking_input() -> bool:
	return result_popup.visible or tutorial_popup.visible


func get_play_area_insets() -> Vector2i:
	var top := PLAY_MARGIN_TOP
	var bottom := PLAY_MARGIN_BOTTOM
	if top_bar and top_bar.size.y > 1.0:
		top = int(top_bar.size.y) + 4
	if bottom_bar and bottom_bar.size.y > 1.0:
		bottom = int(bottom_bar.size.y) + 4
	return Vector2i(top, bottom)


func _process(delta: float) -> void:
	if _hint_timer > 0.0:
		_hint_timer -= delta
		if _hint_timer <= 0.0:
			hint_label.text = "Trái: di chuyển | Phải: bắn | Radar tự quét ô đi được"


func show_tutorial() -> void:
	tutorial_body.text = TUTORIAL_TEXT
	tutorial_popup.show()


func _on_start_pressed() -> void:
	tutorial_popup.hide()
	tutorial_finished.emit()


func _setup_bullet_icons() -> void:
	for icon in [bullet_icon_1, bullet_icon_2, bullet_icon_3]:
		if icon:
			icon.text = "●"
			icon.add_theme_font_size_override("font_size", 18)
			icon.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))


func bind_to_game_state() -> void:
	if not GameState.bullets_changed.is_connected(_on_bullets_changed):
		GameState.bullets_changed.connect(_on_bullets_changed)
	if not GameState.game_over.is_connected(_on_game_over):
		GameState.game_over.connect(_on_game_over)
	if not GameState.game_won.is_connected(_on_game_won):
		GameState.game_won.connect(_on_game_won)
	if not TurnManager.player_turn_started.is_connected(_on_player_turn_started):
		TurnManager.player_turn_started.connect(_on_player_turn_started)
	_last_bullet_count = GameState.bullet_count
	refresh_display()


func connect_player(player: Player) -> void:
	if not is_instance_valid(player):
		return
	if not player.health_changed.is_connected(_on_health_changed):
		player.health_changed.connect(_on_health_changed)
	if not player.player_died.is_connected(_on_player_died):
		player.player_died.connect(_on_player_died)
	refresh_display()


func refresh_display() -> void:
	_update_bullet_icons(GameState.bullet_count)
	turn_label.text = "Lượt %d" % maxi(GameState.current_turn, 1)
	if is_instance_valid(GameState.player_ref) and GameState.player_ref is Player:
		var p := GameState.player_ref as Player
		hp_label.text = "HP: %d/%d" % [p.get_hp(), Player.MAX_HP]


func set_phase_text(text: String) -> void:
	phase_label.text = text


func show_hint(text: String) -> void:
	hint_label.text = text
	_hint_timer = 4.0


func play_defeat_flash() -> void:
	defeat_flash.modulate = Color(1, 0.15, 0.1, 0.65)
	var tween := create_tween()
	tween.tween_property(defeat_flash, "modulate:a", 0.0, 0.85).set_ease(Tween.EASE_OUT)


func _on_bullets_changed(new_count: int) -> void:
	if new_count > _last_bullet_count:
		show_hint("Nhận thêm đạn! (%d/%d)" % [new_count, GameState.MAX_BULLETS_STORED])
	_last_bullet_count = new_count
	_update_bullet_icons(new_count)


func _on_player_turn_started() -> void:
	set_phase_text("▶ Lượt bạn")
	refresh_display()


func _on_health_changed(new_hp: int, max_hp: int) -> void:
	hp_label.text = "HP: %d/%d" % [new_hp, max_hp]


func _on_player_died() -> void:
	play_defeat_flash()


func _on_game_over(reason: String) -> void:
	play_defeat_flash()
	result_label.text = "THUA"
	result_label.modulate = Color(1.0, 0.4, 0.4)
	result_detail.text = _defeat_message(reason)
	_show_result_popup()


func _on_game_won() -> void:
	result_label.text = "CHIẾN THẮNG!"
	result_label.modulate = Color(1.0, 0.92, 0.35)
	var detail := WIN_TIPS
	if GameState.win_reason == "hunter_lured":
		detail = "Bạn đã dụ Hunter vào hỏa lực pháo!\n\n" + WIN_TIPS
	elif GameState.win_reason == "base_captured":
		detail = "Bạn đã chiếm căn cứ địch!\n\n" + WIN_TIPS
	result_detail.text = detail
	_show_result_popup()


func _show_result_popup() -> void:
	result_popup.show()
	result_popup.mouse_filter = Control.MOUSE_FILTER_STOP
	result_popup.z_index = 200
	restart_button.mouse_filter = Control.MOUSE_FILTER_STOP
	restart_button.disabled = false
	restart_button.grab_focus()


func _defeat_message(reason: String) -> String:
	var base := reason + "\n\nGợi ý:\n• Xem vòng xanh Radar trên ô đi được.\n• Tránh ô pháo đỏ.\n• Tiết kiệm đạn — +1 mỗi 3 lượt."
	if "mìn" in reason.to_lower() or "mine" in reason.to_lower():
		return "Bạn dẫm phải bãi mìn.\n\n" + base
	if "bao vây" in reason.to_lower() or "đường thoát" in reason.to_lower():
		return reason + "\n\nGợi ý: Giữ lối lui, dùng đạn phá bẫy khi cần."
	if "hunter" in reason.to_lower() or "tầm bắn" in reason.to_lower():
		return reason + "\n\n" + base
	if "pháo" in reason.to_lower() or "turret" in reason.to_lower():
		return "Bạn bị pháo tiêu diệt.\n\n" + base
	return base


func setup_restart(host: Node) -> void:
	_restart_host = host
	_mount_result_popup(host)
	if restart_button.pressed.is_connected(_on_restart_pressed):
		restart_button.pressed.disconnect(_on_restart_pressed)
	restart_button.pressed.connect(_on_restart_pressed)


func _mount_result_popup(host: Node) -> void:
	if not is_instance_valid(host):
		return
	var layer := host.get_node_or_null("PopupLayer") as CanvasLayer
	if layer == null:
		return
	if result_popup.get_parent() == layer:
		return
	result_popup.reparent(layer)
	result_popup.set_anchors_preset(Control.PRESET_CENTER)
	result_popup.offset_left = -280.0
	result_popup.offset_top = -160.0
	result_popup.offset_right = 280.0
	result_popup.offset_bottom = 160.0


func _on_restart_pressed() -> void:
	restart_button.disabled = true
	get_viewport().set_input_as_handled()
	result_popup.hide()
	defeat_flash.modulate.a = 0.0
	GameState.prepare_for_restart()
	TurnManager.reset_turn_system()
	if is_instance_valid(_restart_host) and _restart_host.has_method("restart_game"):
		_restart_host.restart_game()
	else:
		get_tree().change_scene_to_file("res://Main.tscn")


func _update_bullet_icons(count: int) -> void:
	var icons := [bullet_icon_1, bullet_icon_2, bullet_icon_3]
	for i in icons.size():
		if icons[i] == null:
			continue
		icons[i].modulate = Color.WHITE if count >= i + 1 else Color(1, 1, 1, 0.2)
