extends Node

func _ready() -> void:
	const TILE_SIZE := 32
	const COLS := 5
	const ROWS := 2
	var width := TILE_SIZE * COLS
	var height := TILE_SIZE * ROWS
	var img := Image.create(width, height, false, Image.FORMAT_RGB8)
	img.fill(Color(0.08, 0.09, 0.11))

	_paint_tile(img, 0, 0, Color(0.30, 0.55, 0.29), Color(0.12, 0.14, 0.17))
	_paint_tile(img, 4, 0, Color(0.25, 0.47, 0.24), Color(0.12, 0.14, 0.17))
	_paint_tile(img, 1, 0, Color(0.36, 0.25, 0.22), Color(0.12, 0.14, 0.17))
	_paint_tile(img, 2, 0, Color(1.0, 0.76, 0.03), Color(0.12, 0.14, 0.17))
	_paint_tile(img, 3, 0, Color(0.47, 0.47, 0.51), Color(0.12, 0.14, 0.17))
	_paint_tile(img, 0, 1, Color(0.24, 0.78, 0.82), Color(0.12, 0.14, 0.17))
	_paint_tile(img, 1, 1, Color(0.86, 0.24, 0.31), Color(0.12, 0.14, 0.17))

	var err := img.save_png("res://tiles_placeholder.png")
	if err == OK:
		print("tiles_placeholder.png đã lưu (", width, "x", height, ")")
	get_tree().quit()


func _paint_tile(img: Image, col: int, row: int, fill: Color, border: Color) -> void:
	var t := 32
	var x := col * t
	var y := row * t
	for px in range(t):
		for py in range(t):
			var on_border := px < 2 or py < 2 or px >= t - 2 or py >= t - 2
			img.set_pixel(x + px, y + py, border if on_border else fill)
