extends Control
class_name MapHoverInfo

## Đã tắt — radar dùng AutoRadar. Giữ node để không vỡ scene.


func _ready() -> void:
	visible = false
	set_process(false)
