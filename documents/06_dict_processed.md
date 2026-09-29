# TỪ ĐIỂN DỮ LIỆU CÁC FILE ĐÃ GỘP (PROCESSED DATA DICTIONARY)

Tài liệu này giải thích chi tiết cấu trúc, nguồn gốc và ý nghĩa nghiệp vụ của từng cột trong 4 file dữ liệu đã được làm sạch và hợp nhất nằm trong thư mục `dataset/processed/`:
1. `teams_merged.csv` (30 dòng, 11 cột)
2. `players_merged.csv` (4,831 dòng, 23 cột)
3. `games_merged.csv` (65,642 dòng, 30 cột)
4. `player_game.csv` (617,110 dòng, 3 cột)

---

## 1. FILE `teams_merged.csv` (30 dòng, 11 cột)

* **Mục tiêu:** Lưu trữ hồ sơ định danh, cơ sở vật chất sân bãi và bộ máy quản lý của 30 đội bóng tại giải NBA (dùng nạp cho `dim_team` và `dim_arena`).
* **Nguồn gộp:** `team.csv` + `team_details.csv` (ghép qua khóa `team_id`).

| STT | Tên cột | Kiểu dữ liệu | Ý nghĩa nghiệp vụ | Nguồn gốc |
|:---:|---|:---:|---|---|
| 1 | `team_id` | BIGINT | Mã định danh duy nhất của đội bóng (Primary Key). | `team.id` |
| 2 | `full_name` | VARCHAR | Tên đầy đủ chính thức của đội (vd: *Los Angeles Lakers*). | `team.full_name` |
| 3 | `abbreviation` | VARCHAR(5) | Tên viết tắt chuẩn của đội (vd: *LAL, GSW, BOS*). | `team.abbreviation` |
| 4 | `city` | VARCHAR | Thành phố nơi đội bóng đặt trụ sở sân nhà (vd: *Los Angeles*). | `team.city` |
| 5 | `state` | VARCHAR | Bang trực thuộc tại Mỹ. | `team.state` |
| 6 | `year_founded` | FLOAT/INT | Năm thành lập đội bóng (vd: *1946, 1948*). | `team.year_founded` |
| 7 | `arena` | VARCHAR | Tên nhà thi đấu / Sân vận động sân nhà (vd: *Crypto.com Arena*). | `team_details.arena` |
| 8 | `arena_capacity` | FLOAT/INT | Sức chứa khán giả tối đa của nhà thi đấu (chỗ ngồi). | `team_details.arenacapacity` |
| 9 | `owner` | VARCHAR | Chủ sở hữu / Tỷ phú sở hữu nhượng quyền đội bóng. | `team_details.owner` |
| 10 | `general_manager` | VARCHAR | Tổng giám đốc điều hành chuyên môn (General Manager - GM). | `team_details.generalmanager` |
| 11 | `head_coach` | VARCHAR | Huấn luyện viên trưởng đương nhiệm của đội. | `team_details.headcoach` |

---

## 2. FILE `players_merged.csv` (4,831 dòng, 23 cột)

* **Mục tiêu:** Lưu trữ hồ sơ của 4,831 cầu thủ từng thi đấu tại NBA từ 1946 đến nay: tiểu sử, thông số hình thể, lịch sử tuyển chọn (Draft), và chỉ số thể chất (dùng nạp cho `dim_player`).
* **Nguồn gộp:** `player.csv` + `common_player_info.csv` + `draft_history.csv` + `draft_combine_stats.csv`.

| STT | Tên cột | Kiểu dữ liệu | Ý nghĩa nghiệp vụ |
|:---:|---|:---:|---|
| 1 | `player_id` | INT | Mã định danh duy nhất của cầu thủ (Primary Key). |
| 2 | `full_name` | VARCHAR | Họ và tên đầy đủ của cầu thủ (vd: *Michael Jordan*). |
| 3 | `is_active` | SMALLINT | Cờ trạng thái thi đấu (`1` = Còn thi đấu, `0` = Đã giải nghệ). |
| 4 | `birthdate` | TIMESTAMP | Ngày tháng năm sinh của cầu thủ. |
| 5 | `school` | VARCHAR | Trường đại học/cao đẳng từng thi đấu trước khi vào NBA. |
| 6 | `country` | VARCHAR | Quốc tịch hoặc quốc gia nơi cầu thủ sinh ra. |
| 7 | `height` | VARCHAR | Chiều cao theo hệ đo lường Mỹ (Feet-Inches, vd: `6-6` ~ 198cm). |
| 8 | `weight` | FLOAT | Cân nặng đo bằng Pounds (lbs). |
| 9 | `season_exp` | FLOAT | Số năm kinh nghiệm thi đấu chuyên nghiệp tại NBA. |
| 10 | `jersey` | VARCHAR | Số áo thi đấu trên sân (vd: *23, 24, 30*). |
| 11 | `position` | VARCHAR | Vị trí thi đấu trên sân: `Guard`, `Forward`, `Center`. |
| 12 | `from_year` | FLOAT | Năm đầu tiên chính thức ra sân tại NBA (Rookie year). |
| 13 | `to_year` | FLOAT | Năm cuối cùng còn thi đấu tại NBA. |
| 14 | `draft_season` | FLOAT | Mùa giải diễn ra kỳ tuyển chọn tân binh. |
| 15 | `draft_round_num` | FLOAT | Số thứ tự vòng tuyển chọn (Round 1, Round 2). |
| 16 | `draft_round_pick`| FLOAT | Lượt chọn trong vòng. |
| 17 | `draft_overall_pick`| FLOAT | Thứ tự chọn tổng thể toàn kỳ Draft (Pick #1 là Trạng nguyên). |
| 18 | `draft_college_or_org` | VARCHAR | Trường hoặc CLB đào tạo trước khi vào NBA. |
| 19 | `draft_org_type` | VARCHAR | Loại hình tổ chức (`College/University`, `International`...). |
| 20 | `height_w_shoes` | FLOAT | Chiều cao khi đi giày thi đấu (Inches). |
| 21 | `wingspan` | FLOAT | Sải tay (khoảng cách 2 đầu ngón tay khi dang ngang, Inches). |
| 22 | `max_vertical_leap` | FLOAT | Độ cao bật nhảy tối đa có bước đà (Inches). |
| 23 | `bench_press` | FLOAT | Số lần đẩy tạ nằm mức chuẩn 185 lbs (~84 kg). |

---

## 3. FILE `games_merged.csv` (65,642 dòng, 30 cột)

* **Mục tiêu:** Lưu trữ 65,642 trận đấu trong lịch sử NBA (1946–2023). Bảng này là nguồn trực tiếp để unpivot tạo nên bảng Fact `fact_team_game` trong Data Warehouse.
* **Nguồn gộp:** `game.csv` + `game_info.csv` + `game_summary.csv` + `other_stats.csv` + `line_score.csv`.

| STT | Tên cột | Kiểu dữ liệu | Ý nghĩa nghiệp vụ |
|:---:|---|:---:|---|
| 1 | `game_id` | NVARCHAR | Mã định danh duy nhất của trận đấu (Degenerate Dimension). |
| 2 | `game_date` | TIMESTAMP | Ngày và giờ diễn ra trận đấu. |
| 3 | `season_id` | INT | Mã mùa giải (vd: `22022` là Regular Season mùa 2022-23). |
| 4 | `season_type` | VARCHAR | Loại mùa giải: `Regular Season`, `Playoffs`, `All-Star`. |
| 5 | `team_id_home` | BIGINT | Mã đội Chủ nhà (`_home`). |
| 6 | `team_id_away` | BIGINT | Mã đội Khách (`_away`). |
| 7, 19 | `wl_home` / `_away` | VARCHAR(1) | Kết quả trận đấu: `W` (Thắng), `L` (Thua). |
| 8, 20 | `pts_home` / `_away` | FLOAT | Điểm ghi được của từng đội. |
| 9, 21 | `plus_minus_home` / `_away` | INT | Hiệu số điểm bàn thắng/bại. |
| 10, 22 | `fgm_home` / `_away` | FLOAT | Field Goals Made (Ném rổ trúng). |
| 11, 23 | `fga_home` / `_away` | FLOAT | Field Goals Attempted (Số lần dứt điểm). |
| 12, 24 | `fg3m_home` / `_away` | FLOAT | 3-Point Made (Ném 3 điểm trúng). |
| 13, 25 | `fg3a_home` / `_away` | FLOAT | 3-Point Attempted (Số lần ném 3 điểm). |
| 14, 26 | `reb_home` / `_away` | FLOAT | Total Rebounds (Tổng bắt bóng bật bảng). |
| 15, 27 | `ast_home` / `_away` | FLOAT | Assists (Số pha kiến tạo thành bàn). |
| 16, 28 | `tov_home` / `_away` | FLOAT | Turnovers (Số lần làm mất bóng). |
| 17, 29 | `pts_paint_home` / `_away` | FLOAT | Points in the Paint (Điểm vùng cận rổ). |
| 18, 30 | `pts_fb_home` / `_away` | FLOAT | Fast Break Points (Điểm phản công nhanh). |

---

## 4. FILE `player_game.csv` (617,110 dòng, 3 cột)

* **Mục tiêu:** Cung cấp liên kết nhiều-nhiều giữa Cầu thủ và Trận đấu/Đội bóng (dùng nạp cho bảng cầu nối `player_game` trong Data Warehouse).
* **Nguồn trích xuất:** `play_by_play.csv` (2.2GB, ~13.6 triệu dòng event).
* **Quy trình làm sạch:**
  1. Loại bỏ các event cấp đội bóng (có `player_id > 1,610,000,000`).
  2. Loại bỏ các dòng có `team_id = NULL`.
  3. Đảm bảo toàn vẹn khóa ngoại: Chỉ giữ lại các `player_id` tồn tại trong `players_merged.csv` và `team_id` tồn tại trong `teams_merged.csv`.

| STT | Tên cột | Kiểu dữ liệu | Ý nghĩa nghiệp vụ | Khóa liên kết |
|:---:|---|:---:|---|---|
| 1 | `game_id` | NVARCHAR(30) | Mã trận đấu NBA diễn ra sự kiện. | Liên kết với `fact_team_game.game_id` |
| 2 | `player_id` | INT | Mã định danh duy nhất của cầu thủ tham gia trận đấu. | Foreign Key $\rightarrow$ `dim_player.player_id` |
| 3 | `team_id` | BIGINT | Mã đội bóng mà cầu thủ khoác áo trong trận đấu này. | Foreign Key $\rightarrow$ `dim_team.team_id` |
