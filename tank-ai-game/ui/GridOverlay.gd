extends Node2D
class_name GridOverlay

var grid_width: int = 12
var grid_height: int = 12
var tile_size: Vector2i = Vector2i(32, 32)

## cell -> Color (vàng = ngắm, đỏ = bắn)
var turret_marks: Dictionary = {}
var radar_cells: Array[Vector2i] = []


func configure(width: int, height: int, ts: Vector2i) -> void:
	grid_width = width
	grid_height = height
	tile_size = ts
	queue_redraw()


func set_turret_marks(marks: Dictionary) -> void:
	turret_marks = marks.duplicate()
	queue_redraw()


func set_radar_cells(cells: Array[Vector2i]) -> void:
	radar_cells = cells.duplicate()
	queue_redraw()


func _draw() -> void:
	var ts := Vector2(tile_size)
	var map_size := Vector2(grid_width * ts.x, grid_height * ts.y)
	var line_color := Color(0.22, 0.28, 0.34, 0.9)
	for x in range(grid_width + 1):
		var px := x * ts.x
		draw_line(Vector2(px, 0), Vector2(px, map_size.y), line_color, 1.0)
	for y in range(grid_height + 1):
		var py := y * ts.y
		draw_line(Vector2(0, py), Vector2(map_size.x, py), line_color, 1.0)

	for cell: Vector2i in turret_marks:
		var col: Color = turret_marks[cell]
		var tl := Vector2(cell.x * ts.x, cell.y * ts.y)
		var rect := Rect2(tl, ts)
		draw_rect(rect, Color(col.r, col.g, col.b, 0.38), true)
		draw_rect(rect, col, false, 3.0)

	for cell: Vector2i in radar_cells:
		var center := Vector2((cell.x + 0.5) * ts.x, (cell.y + 0.5) * ts.y)
		draw_arc(center, ts.x * 0.32, 0.0, TAU, 24, Color(0.2, 0.85, 1.0, 0.85), 2.5)
		draw_circle(center, 4.0, Color(0.2, 0.85, 1.0, 0.5))
