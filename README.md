# Xây dựng AI Tìm Đường và Suy Luận Trạng Thái cho Game Xe Tăng (Nhóm 074)

## 1. Tổng quan đồ án
Đồ án xây dựng một game **chiến thuật theo lượt trên không gian lưới 2D** (grid-based turn-based strategy), nơi người chơi điều khiển xe tăng di chuyển theo ô và đưa ra quyết định theo từng lượt.

Hai hệ thống AI lõi của đồ án:
- **AI Tìm đường A\***: tính đường đi trên lưới, cập nhật vật cản động (tường, mìn, pháo) để Hunter truy đuổi.
- **AI Suy luận/nhận thức khi mất tầm nhìn**: lưu “vị trí quan sát gần nhất” của Player và cung cấp vị trí dự đoán để AI tiếp tục truy đuổi khi không còn quan sát trực tiếp (InferenceSystem).

## 2. Công nghệ sử dụng
- **Godot Engine 4.6**
- **GDScript**

## 3. Kiến trúc & luồng hoạt động
Godot project nằm trong thư mục `tank-ai-game/` (file cấu hình: `tank-ai-game/project.godot`). Scene chạy chính là `Main.tscn`.

### Thành phần lõi
- `GameState.gd` (Autoload/Singleton): lưu trạng thái toàn cục của ván chơi (lượt hiện tại, số đạn, danh sách turret/trap, vị trí các thực thể, stun, tín hiệu thắng/thua).
- `TurnManager.gd` (Autoload/Singleton): điều phối vòng lặp lượt theo pha:
  - `PLAYER` → `TURRET` → `HUNTER` → `RESOLUTION` → quay lại `PLAYER`
  - Cuối lượt: tick stun, kiểm tra trạng thái và thưởng đạn theo chu kỳ.

### Luồng khởi tạo ván (Main)
- `Main.gd` reset hệ thống, gọi `MapGenerator.generate_map()` để sinh bản đồ + spawn thực thể, sau đó bắt đầu vòng lặp lượt qua `TurnManager.start_turn()`.

### AI trong dự án
- `AStarHunter.gd`: triển khai A\* trên grid (heuristic Manhattan), rebuild navigation theo trạng thái mới nhất của map/trap/turret.
- `InferenceSystem.gd`: lưu quan sát (ô cuối cùng thấy Player + lượt) và cung cấp API lấy vị trí dự đoán (`get_best_guess_position()`), dùng như “bộ nhớ” khi AI mất tầm nhìn.

## 4. Hướng dẫn khởi chạy
1. Mở **Godot Engine 4.6**.
2. Chọn **Import** và trỏ tới file `tank-ai-game/project.godot`.
3. Mở scene `Main.tscn` (hoặc nhấn Run nếu project đã set main scene) để chạy game.

## 5. Phân công nhiệm vụ (Nhóm 074)
- **Đinh Việt Hoàng**: Hệ thống Lõi (Core) & Thuật toán AI Tìm đường  
  `Main.gd`, `GameState.gd`, `TurnManager.gd`, `PlayerInput.gd`, `AStarHunter.gd`  
  Xây dựng vòng lặp chuyển lượt và thuật toán A\* để né vật cản.

- **Nguyễn Lê Gia Bảo**: Thực thể (Entities) & Hệ thống AI Suy luận  
  `Player.gd`, `Hunter.gd`, `Turret.gd`, `InferenceSystem.gd`, `MineTrap.gd`, `EMPTrap.gd`, `EnemyBase.gd`, `Bullet.gd`  
  Cài đặt kịch bản di chuyển/bắn, tương tác bẫy và bộ nhớ AI.

- **Nguyễn Trung Hiếu**: Khởi tạo Môi trường (Environment) & Giao diện (UI/VFX)  
  `MapGenerator.gd`, `GridManager.gd`, `GridOverlay.gd`, `HUDControl.gd`, `AutoRadar.gd`, `MapHoverInfo.gd`, `ParticleManager.gd`  
  Viết thuật toán sinh bản đồ, UI hiển thị máu/đạn và quét Radar.
