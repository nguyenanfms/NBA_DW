# THIẾT KẾ CÁC BẢNG DIMENSION & BẢNG CẦU NỐI TINH GỌN
## (Data Warehouse phục vụ Phân tích Kết quả Trận đấu & Cầu thủ NBA)

Tài liệu này đặc tả chi tiết **5 bảng chiều (Dimension Tables)** và **1 bảng cầu nối (Bridge Table)** trong mô hình Star Schema mở rộng.  
Mỗi cột được chọn lựa dựa trên nguyên tắc:
> **"Mọi thuộc tính của bảng Dimension phải đóng vai trò là nhãn hiển thị (Label), điều kiện lọc (Filter/Slice/Dice), hoặc một cấp bậc trong cây phân tích (Hierarchy Drill-down/Roll-up)."**

---

## 1. BẢNG `dim_date` (Chiều Thời Gian Lịch)

* **Mục tiêu:** Cung cấp các cấp bậc phân tích theo lịch tự nhiên (Năm -> Quý -> Tháng -> Ngày).
* **Nguồn nạp:** Sinh tự động từ dải ngày của cột `game_date` trong `games_merged.csv` (từ 1946 đến 2023).
* **Số dòng:** ~28,000 dòng.

| STT | Tên cột | Kiểu | Vai trò | Chức năng & Câu hỏi truy vấn OLAP minh chứng |
|:---:|---|:---:|:---:|---|
| 1 | `date_key` | INT | **PK** | Khóa chính dạng số nguyên `YYYYMMDD` (vd: `20230512`). Khớp với `fact_team_game.date_key`. |
| 2 | `full_date` | DATE | Thuộc tính | Ngày đầy đủ dạng chuẩn `YYYY-MM-DD`. Dùng để hiển thị trên báo cáo và trục thời gian. |
| 3 | `year_number` | SMALLINT | Cấp bậc 1 | Năm thi đấu (vd: `2023`).<br>👉 *Truy vấn:* So sánh tổng số trận đấu và điểm số toàn giải qua từng năm? |
| 4 | `quarter_number`| TINYINT | Cấp bậc 2 | Quý trong năm (`1`, `2`, `3`, `4`).<br>👉 *Truy vấn:* Phân tích kết quả thi đấu theo từng Quý của năm tài chính thể thao? |
| 5 | `month_number` | TINYINT | Cấp bậc 3 | Tháng dạng số (`1` đến `12`). Dùng để sắp xếp (Sort) theo thứ tự thời gian. |
| 6 | `month_name` | NVARCHAR(15)| Nhãn hiển thị | Tên tháng bằng chữ (*January, February...*). Dùng để hiển thị trên biểu đồ Dashboard. |
| 7 | `day_of_week_name`| NVARCHAR(15)| Nhãn hiển thị | Thứ trong tuần (*Monday, Tuesday... Sunday*).<br>👉 *Truy vấn:* Các đội thi đấu vào Thứ Bảy hay Chủ Nhật có tỷ lệ thắng sân khách cao hơn? |
| 8 | `is_weekend` | BIT | Điều kiện lọc (Slice) | Cờ ngày cuối tuần (`1` nếu là Thứ Bảy / Chủ Nhật, `0` nếu ngày thường).<br>👉 *Truy vấn:* So sánh điểm số các trận cuối tuần vs ngày trong tuần? |

---

## 2. BẢNG `dim_season` (Chiều Mùa Giải & Kỷ Nguyên)

* **Mục tiêu:** Phân tích sự tiến hóa của giải đấu NBA theo giai đoạn mùa giải và theo dòng chảy lịch sử.
* **Nguồn nạp:** Trích xuất các giá trị phân biệt từ `season_id` và `season_type` trong `games_merged.csv`.
* **Số dòng:** 225 dòng (tổ hợp mùa giải và loại mùa giải, 100% không trùng lặp).

| STT | Tên cột | Kiểu | Vai trò | Chức năng & Câu hỏi truy vấn OLAP minh chứng |
|:---:|---|:---:|:---:|---|
| 1 | `season_id` | INT | **PK (Natural Key)** | Mã mùa giải gốc từ NBA API (vd: `22022`). Đã kiểm tra 225 giá trị duy nhất, dùng trực tiếp làm PK không cần cột tự tăng. |
| 2 | `season_display`| NVARCHAR(15)| Nhãn hiển thị | Tên mùa giải quen thuộc hiển thị với người dùng (vd: `2022-23`, `2015-16`). |
| 3 | `season_type` | NVARCHAR(30)| Điều kiện lọc (Slice) | Giai đoạn giải đấu: `Regular Season`, `Playoffs`, `All-Star`, `Pre Season`.<br>👉 *Truy vấn:* So sánh tỷ lệ thắng và hiệu suất phòng ngự của đội khi đá Regular Season vs khi vào Playoffs căng thẳng? |
| 4 | `era_name` | NVARCHAR(50)| Cấp bậc cao nhất | **Phân loại 4 Kỷ nguyên lịch sử NBA**:<br>1. *Early Pioneer Era* (1946–1979)<br>2. *Magic-Bird & Jordan Era* (1980–1998)<br>3. *Pace & Space / Modern Era* (1999–2013)<br>4. *3-Point Revolution Era* (2014–Nay)<br>👉 *Truy vấn:* Tỷ lệ ném 3 điểm (`fg3a / fga`) đã thay đổi bùng nổ như thế nào giữa 4 kỷ nguyên? |

---

## 3. BẢNG `dim_team` (Chiều Đội Bóng)

* **Mục tiêu:** Quản lý cấu trúc phân cấp địa lý và tổ chức của 30 đội bóng NBA. Bảng này được áp dụng kỹ thuật **Role-Playing Dimension** (được bảng Fact tham chiếu 2 lần cho `team_id` và `opponent_id`).
* **Nguồn nạp:** `dataset/processed/teams_merged.csv` + Enrichment phân vùng Conference/Division.
* **Số dòng:** 30 dòng (đúng 30 câu lạc bộ NBA, 100% không trùng lặp).

| STT | Tên cột | Kiểu | Vai trò | Chức năng & Câu hỏi truy vấn OLAP minh chứng |
|:---:|---|:---:|:---:|---|
| 1 | `team_id` | BIGINT | **PK (Natural Key)** | Mã định danh gốc của đội từ NBA (vd: `1610612747` = LA Lakers). Ổn định và không duplicate, dùng làm PK. |
| 2 | `full_name` | NVARCHAR(100)| Nhãn hiển thị | Tên đầy đủ chính thức của đội (vd: *Los Angeles Lakers*). |
| 3 | `abbreviation` | NVARCHAR(10) | Nhãn ngắn | Viết tắt 3 chữ cái chuẩn (vd: *LAL, GSW, BOS*). |
| 4 | `city` | NVARCHAR(50)| Cấp bậc địa lý | Thành phố đóng quân (vd: *Los Angeles, Boston, San Francisco*). |
| 5 | `state` | NVARCHAR(50)| Cấp bậc địa lý | Bang tại Mỹ (vd: *California, Massachusetts*). |
| 6 | `conference` | NVARCHAR(30)| Cấp bậc 1 (Cây NBA) | Liên đoàn / Miền thi đấu: `Eastern Conference` hoặc `Western Conference`.<br>👉 *Truy vấn:* Miền nào có tỷ lệ thắng đối đầu liên hội (Inter-conference) áp đảo trong 10 năm qua? |
| 7 | `division` | NVARCHAR(30)| Cấp bậc 2 (Cây NBA) | 6 Phân khu thi đấu (*Atlantic, Central, Southeast, Northwest, Pacific, Southwest*). |

---

## 4. BẢNG `dim_arena` (Chiều Nhà Thi Đấu / Sân Vận Động)

* **Mục tiêu:** Phân tích khía cạnh địa điểm tổ chức thi đấu, sức chứa và yếu tố huấn luyện viên trưởng.
* **Nguồn nạp:** Trích xuất các thuộc tính sân bãi và quản lý từ `dataset/processed/teams_merged.csv`.
* **Số dòng:** 30 dòng (tương ứng các nhà thi đấu sân nhà).

| STT | Tên cột | Kiểu | Vai trò | Chức năng & Câu hỏi truy vấn OLAP minh chứng |
|:---:|---|:---:|:---:|---|
| 1 | `arena_key` | INT | **PK (Surrogate)** | Khóa chính thay thế tự tăng (`IDENTITY(1,1)`). |
| 2 | `arena_name` | NVARCHAR(100)| Nhãn hiển thị | Tên nhà thi đấu (vd: *Crypto.com Arena, Chase Center, TD Garden*). |
| 3 | `arena_capacity`| INT | Thuộc tính số đo | Sức chứa khán giả tối đa (số ghế ngồi). |
| 4 | `city` | NVARCHAR(50)| Cấp bậc địa lý | Thành phố đặt sân vận động. |
| 5 | `owner` | NVARCHAR(100)| Thuộc tính mô tả | Tỷ phú / Chủ sở hữu đội bóng sở hữu sân đấu. |
| 6 | `head_coach` | NVARCHAR(100)| Điều kiện lọc | Huấn luyện viên trưởng. |

---

## 5. BẢNG `dim_player` (Chiều Cầu Thủ — Bổ sung Mới)

* **Mục tiêu:** Quản lý hồ sơ định danh, thông tin thể chất, xuất thân và lịch sử tuyển chọn (Draft) của 4,831 cầu thủ NBA.
* **Nguồn nạp:** `dataset/processed/players_merged.csv`.
* **Số dòng:** 4,831 dòng (100% không trùng lặp, không null tại `player_id`).

| STT | Tên cột | Kiểu | Vai trò | Chức năng & Câu hỏi truy vấn OLAP minh chứng |
|:---:|---|:---:|:---:|---|
| 1 | `player_id` | INT | **PK (Natural Key)** | Mã định danh duy nhất của cầu thủ do NBA cấp (vd: `2544` = LeBron James). Không trùng lặp, làm PK. |
| 2 | `full_name` | NVARCHAR(100)| Nhãn hiển thị | Họ và tên đầy đủ của cầu thủ (vd: *LeBron James, Stephen Curry*). |
| 3 | `is_active` | BIT | Điều kiện lọc | Trạng thái: `1` = Đang thi đấu, `0` = Đã giải nghệ. |
| 4 | `position` | NVARCHAR(30) | Cấp bậc vị trí | Vị trí thi đấu trên sân: *Guard, Forward, Center...*<br>👉 *Truy vấn:* Vị trí nào xuất hiện nhiều nhất trong các trận Playoffs? |
| 5 | `height` | NVARCHAR(10) | Thuộc tính thể chất | Chiều cao (Feet-Inches, vd: `6-9`). |
| 6 | `weight` | FLOAT | Thuộc tính thể chất | Cân nặng (Pounds - lbs). |
| 7 | `country` | NVARCHAR(50) | Cấp bậc địa lý | Quốc gia / Quốc tịch (vd: *USA, France, Serbia...*).<br>👉 *Truy vấn:* Số lượng trận đấu có sự tham gia của các cầu thủ quốc tế (ngoài Mỹ) tăng trưởng ra sao? |
| 8 | `birthdate` | DATE | Thuộc tính | Ngày tháng năm sinh. |
| 9 | `draft_round_num` | INT | Phân loại tuyển chọn | Vòng tuyển chọn tân binh (`1`, `2` hoặc `NULL` nếu Undrafted). |
| 10 | `draft_overall_pick`| INT | Phân loại tuyển chọn | Lượt chọn tổng thể toàn kỳ Draft (Pick #1 là Trạng nguyên). |
| 11 | `from_year` | SMALLINT | Mốc thời gian | Năm bắt đầu sự nghiệp tại NBA. |
| 12 | `to_year` | SMALLINT | Mốc thời gian | Năm giải nghệ hoặc năm thi đấu gần nhất. |

---

## 6. BẢNG `player_game` (Bảng Cầu Nối Cầu Thủ ↔ Trận Đấu)

* **Mục tiêu:** Giải quyết mối quan hệ **Nhiều - Nhiều (Many-to-Many)** giữa cầu thủ và trận đấu/đội bóng mà **không làm thay đổi hạt dữ liệu (Grain)** của bảng Fact `fact_team_game`.
* **Nguồn nạp:** `dataset/processed/player_game.csv` (Trích xuất từ 2.2GB `play_by_play.csv`).
* **Số dòng:** 617,110 dòng sạch (đã kiểm tra toàn vẹn khóa ngoại FK với `dim_player` và `dim_team`).

| STT | Tên cột | Kiểu | Vai trò | Chức năng & Ý nghĩa nghiệp vụ |
|:---:|---|:---:|:---:|---|
| 1 | `game_id` | NVARCHAR(30) | **Composite PK, FK** | Mã trận đấu — kết nối với `fact_team_game.game_id`. |
| 2 | `player_id` | INT | **Composite PK, FK** | Mã cầu thủ — FK trỏ sang `dim_player.player_id`. |
| 3 | `team_id` | BIGINT | **FK** | Mã đội bóng mà cầu thủ khoác áo trong trận đấu cụ thể này — FK trỏ sang `dim_team.team_id`. |

---

## 7. TỔNG KẾT CÁC CÂY PHÂN CẤP ĐA CHIỀU (DRILL-DOWN HIERARCHIES)

1. **Cây Giải đấu (League Hierarchy):**
   $$\text{NBA League} \longrightarrow \text{Conference (2 Miền)} \longrightarrow \text{Division (6 Phân khu)} \longrightarrow \text{Team (30 Đội)}$$
2. **Cây Thời gian Lịch (Calendar Hierarchy):**
   $$\text{Year (Năm)} \longrightarrow \text{Quarter (Quý)} \longrightarrow \text{Month (Tháng)} \longrightarrow \text{Date (Ngày)}$$
3. **Cây Kỷ nguyên & Mùa giải (Season Hierarchy):**
   $$\text{Era (4 Kỷ nguyên)} \longrightarrow \text{Season (Mùa giải)} \longrightarrow \text{Season Type (Regular / Playoffs)}$$
4. **Cây Cầu thủ (Player Hierarchy):**
   $$\text{Country (Quốc gia)} \longrightarrow \text{Position (Vị trí thi đấu)} \longrightarrow \text{Player (Cầu thủ)}$$
5. **Cây Địa điểm (Venue Hierarchy):**
   $$\text{State (Bang)} \longrightarrow \text{City (Thành phố)} \longrightarrow \text{Arena (Nhà thi đấu)}$$
