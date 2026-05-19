extends Node2D

func _ready():
	# Kích thước chung cho mọi ảnh placeholder
	const S = 64

	# --- PLAYER TANK ---
	var p = Image.create(S, S, false, Image.FORMAT_RGBA8)
	p.fill(Color(0,0,0,0))
	p.fill_rect(Rect2i(8, 20, 48, 30), Color("#4A6B3A"))
	p.fill_rect(Rect2i(4, 18, 8, 34), Color("#3A3A3A"))
	p.fill_rect(Rect2i(52, 18, 8, 34), Color("#3A3A3A"))
	p.fill_rect(Rect2i(20, 4, 24, 20), Color("#5B8C42"))
	p.fill_rect(Rect2i(28, 0, 8, 12), Color("#6B6B6B"))
	p.fill_rect(Rect2i(26, 8, 4, 4), Color(0,0,0,0.5))
	p.save_png("res://player_tank.png")

	# --- HUNTER ---
	var h = Image.create(S, S, false, Image.FORMAT_RGBA8)
	h.fill(Color(0,0,0,0))
	h.fill_rect(Rect2i(10, 20, 44, 30), Color("#B71C1C"))
	h.fill_rect(Rect2i(6, 18, 8, 34), Color("#424242"))
	h.fill_rect(Rect2i(50, 18, 8, 34), Color("#424242"))
	h.fill_rect(Rect2i(22, 6, 20, 18), Color("#D32F2F"))
	h.fill_rect(Rect2i(28, 0, 8, 10), Color("#757575"))
	h.fill_rect(Rect2i(26, 10, 4, 4), Color(0,0,0,0.6))
	h.save_png("res://hunter.png")

	# --- TURRET ---
	var t = Image.create(S, S, false, Image.FORMAT_RGBA8)
	t.fill(Color(0,0,0,0))
	t.fill_rect(Rect2i(14, 30, 36, 20), Color("#5D4037"))
	t.fill_rect(Rect2i(26, 0, 12, 32), Color("#795548"))
	t.fill_rect(Rect2i(28, 0, 8, 8), Color("#A1887F"))
	t.fill_rect(Rect2i(20, 28, 24, 4), Color("#3E2723"))
	t.save_png("res://turret.png")

	# --- ENEMY BASE ---
	var eb = Image.create(S, S, false, Image.FORMAT_RGBA8)
	eb.fill(Color(0,0,0,0))
	eb.fill_rect(Rect2i(4, 4, 56, 56), Color("#4A0000"))
	eb.fill_rect(Rect2i(10, 10, 44, 44), Color("#8B0000"))
	eb.fill_rect(Rect2i(24, 24, 16, 6), Color("#FFC107"))
	eb.fill_rect(Rect2i(28, 30, 8, 6), Color("#FFC107"))
	eb.save_png("res://enemy_base.png")

	# --- MINE TRAP ---
	var m = Image.create(S, S, false, Image.FORMAT_RGBA8)
	m.fill(Color(0,0,0,0))
	m.fill_rect(Rect2i(20, 20, 24, 24), Color("#1A1A1A"))
	m.fill_rect(Rect2i(28, 28, 8, 8), Color("#FF0000"))
	m.fill_rect(Rect2i(24, 16, 4, 8), Color("#888888"))
	m.fill_rect(Rect2i(36, 16, 4, 8), Color("#888888"))
	m.save_png("res://mine_trap.png")

	# --- EMP TRAP ---
	var em = Image.create(S, S, false, Image.FORMAT_RGBA8)
	em.fill(Color(0,0,0,0))
	em.fill_rect(Rect2i(16, 16, 32, 32), Color("#0D47A1"))
	em.fill_rect(Rect2i(24, 24, 16, 16), Color("#42A5F5"))
	em.fill_rect(Rect2i(28, 20, 8, 4), Color("#FFFFFF"))
	em.fill_rect(Rect2i(28, 40, 8, 4), Color("#FFFFFF"))
	em.fill_rect(Rect2i(20, 28, 4, 8), Color("#FFFFFF"))
	em.fill_rect(Rect2i(40, 28, 4, 8), Color("#FFFFFF"))
	em.save_png("res://emp_trap.png")
	
	# --- BULLET ---
	var bullet = Image.create(16, 8, false, Image.FORMAT_RGBA8)
	bullet.fill(Color(0, 0, 0, 0))  # Nền trong suốt

	# Vẽ viên đạn hình elip dài màu vàng sáng
	# Thân đạn (hình chữ nhật bo tròn đơn giản)
	bullet.fill_rect(Rect2i(1, 1, 14, 6), Color("#FFD600"))   # Vàng chủ đạo
	bullet.fill_rect(Rect2i(3, 0, 10, 8), Color("#FFEA00"))   # Vùng sáng hơn ở giữa
	# Điểm nhấn đầu đạn
	bullet.fill_rect(Rect2i(0, 2, 2, 4), Color("#FFAB00"))    # Cam đậm ở mũi

	bullet.save_png("res://bullet.png")
	print("✅ bullet.png đã lưu")

	print("✅ Tất cả ảnh placeholder đã được tạo!")
	get_tree().quit()
