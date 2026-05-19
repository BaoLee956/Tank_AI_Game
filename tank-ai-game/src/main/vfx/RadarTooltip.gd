extends Control
class_name RadarTooltip

@onready var panel: PanelContainer = $Panel
@onready var entity_name_lbl: Label = $Panel/VBox/EntityNameLabel
@onready var entity_info_lbl: Label = $Panel/VBox/EntityInfoLabel

const TOOLTIP_OFFSET: Vector2 = Vector2(12, 12)

@export var grid_manager_path: NodePath
var _grid_mgr: GridManager = null
var _current_cell: Vector2i = Vector2i(-1, -1)


func _ready() -> void:
	panel.hide()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not grid_manager_path.is_empty():
		_grid_mgr = get_node(grid_manager_path) as GridManager
	_apply_panel_style()


func _apply_panel_style() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.1, 0.14, 0.92)
	style.border_color = Color(0.35, 0.75, 0.85, 0.9)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(8)
	panel.add_theme_stylebox_override("panel", style)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_handle_hover((event as InputEventMouseMotion).global_position)


func _handle_hover(mouse_pos: Vector2) -> void:
	if _grid_mgr == null:
		return
	if not _grid_mgr.is_world_on_grid(mouse_pos):
		hide_tooltip()
		return

	var hovered_cell := _grid_mgr.world_to_cell(mouse_pos)
	if hovered_cell == Vector2i(-1, -1):
		hide_tooltip()
		return

	if hovered_cell == _current_cell:
		return

	_current_cell = hovered_cell
	var detected := _scan_surrounding(hovered_cell)
	if detected.is_empty():
		hide_tooltip()
		return

	show_radar_signal(detected)
	_position_panel(mouse_pos)


func _scan_surrounding(center: Vector2i) -> Dictionary:
	var result: Dictionary = {}
	for offset in _neighbor_offsets():
		var cell := center + offset
		if not _grid_mgr.is_in_bounds(cell):
			continue
		var signal_text := _radar_signal_at(cell)
		if signal_text != "":
			result[cell] = signal_text
	return result


func _neighbor_offsets() -> Array[Vector2i]:
	return [
		Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
		Vector2i(-1, 0), Vector2i(1, 0),
		Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1)
	]


func _radar_signal_at(cell: Vector2i) -> String:
	for trap in GameState.traps:
		if trap is Node2D and _grid_mgr:
			var trap_cell := _grid_mgr.local_center_to_cell((trap as Node2D).position)
			if trap_cell != cell:
				continue
			if trap is MineTrap:
				return "Nhiễu kim loại"
			if trap is EMPTrap:
				return "Nhiễu từ trường"
	if GameState.hunter_ref and GameState.get_entity_cell(&"hunter") == cell:
		return "Sóng nhiệt đỏ"
	return ""


func show_radar_signal(detected: Dictionary) -> void:
	var lines: PackedStringArray = []
	for cell in detected:
		lines.append("%s @ %s" % [detected[cell], cell])
	entity_info_lbl.text = "\n".join(lines)
	entity_name_lbl.text = "📡 Radar"
	panel.show()


func hide_tooltip() -> void:
	panel.hide()
	_current_cell = Vector2i(-1, -1)


func _position_panel(mouse_pos: Vector2) -> void:
	panel.reset_size()
	var viewport_size := get_viewport_rect().size
	var tooltip_size := panel.get_minimum_size()
	if tooltip_size == Vector2.ZERO:
		tooltip_size = Vector2(200, 60)
	var target_pos := mouse_pos + TOOLTIP_OFFSET
	target_pos.x = clampf(target_pos.x, 8.0, viewport_size.x - tooltip_size.x - 8.0)
	target_pos.y = clampf(target_pos.y, 96.0, viewport_size.y - tooltip_size.y - 8.0)
	panel.global_position = target_pos
	panel.size = tooltip_size
