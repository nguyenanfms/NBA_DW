# TỪ ĐIỂN DỮ LIỆU CÁC FILE CSV GỐC & TỔNG QUAN TẬP DỮ LIỆU NBA

Tài liệu này giải thích chi tiết:
1. **Bản chất các file định dạng khác ngoài CSV** trong thư mục `dataset/raw/` (`.sqlite`, `.duckdb`, `.json`).
2. **Từ điển dữ liệu (Data Dictionary)** giải thích ý nghĩa từng cột của toàn bộ 16 file CSV gốc trong `dataset/raw/csv/`.

---

## PHẦN 1: CÁC FILE ĐỊNH DẠNG KHÁC NGOÀI CSV LÀ GÌ?

Trong thư mục `dataset/raw/`, ngoài thư mục con `csv/`, bạn sẽ thấy có 4 file:
- `nba.sqlite` (dung lượng ~2.35 GB)
- `nba.duckdb` (dung lượng ~1.8 GB)
- `dataset-metadata.json`
- `run_summary.json`

### 1. File `nba.sqlite` là gì?
- **Định dạng:** Cơ sở dữ liệu quan hệ nhúng (Embedded Relational Database) chuẩn SQLite.
- **Nguồn gốc:** Đây là tệp CSDL gốc ban đầu được tác giả (Wyatt Walsh) crawl từ hệ thống API của NBA (`stats.nba.com`) và đóng gói chia sẻ trên Kaggle.
- **Bên trong chứa gì:** Chứa toàn bộ các bảng dữ liệu của giải đấu NBA từ năm 1946 đến nay. 16 file CSV trong thư mục `dataset/raw/csv/` chính là được trích xuất (export) ra từ các bảng của file SQLite này.

### 2. File `nba.duckdb` là gì?
- **Định dạng:** CSDL quan hệ hướng cột (Columnar OLAP Database) thế hệ mới DuckDB.
- **Mục đích:** DuckDB được thiết kế chuyên biệt cho việc chạy các câu truy vấn phân tích tổng hợp (Analytical / OLAP queries) siêu nhanh trên máy cá nhân, nhanh hơn SQLite từ 10 đến 100 lần khi tính toán `SUM`, `AVG`, `GROUP BY` trên hàng triệu dòng.

### 3. File `dataset-metadata.json` & `run_summary.json` là gì?
- **`dataset-metadata.json`:** File chứa thông tin mô tả (metadata) từ Kaggle: tên tác giả, giấy phép bản quyền (CC-BY-SA-4.0), danh mục 235 bảng và các view phân tích.
- **`run_summary.json`:** File nhật ký ghi lại trạng thái của pipeline crawl dữ liệu (thời gian bắt đầu chạy, số dòng trích xuất).

---

## PHẦN 2: Ý NGHĨA CÁC CỘT CỦA TỪNG FILE CSV GỐC (16 FILES)

---

### NHÓM 1: CÁC FILE VỀ CẦU THỦ (PLAYER DATA)

#### 1. `player.csv` (4,831 dòng, 5 cột) — Danh mục cầu thủ chính
Bảng gốc định danh mọi cầu thủ từng thi đấu tại NBA từ 1946.
- `id`: Mã định danh duy nhất của cầu thủ (Primary Key).
- `full_name`: Họ và tên đầy đủ của cầu thủ (ví dụ: Michael Jordan, LeBron James).
- `first_name`: Tên.
- `last_name`: Họ.
- `is_active`: Cờ trạng thái thi đấu (`1` = Cầu thủ còn đang thi đấu, `0` = Đã giải nghệ).

#### 2. `common_player_info.csv` (4,171 dòng, 33 cột) — Tiểu sử & Thông tin chi tiết
- `person_id`: Mã định danh cầu thủ (khớp với `player.id`).
- `first_name`, `last_name`, `display_first_last`, `display_last_comma_first`, `display_fi_last`, `player_slug`: Các định dạng hiển thị tên và đường dẫn URL web.
- `birthdate`: Ngày tháng năm sinh.
- `school`: Trường đại học/cao đẳng từng theo học trước khi vào NBA (ví dụ: Duke, North Carolina).
- `country`: Quốc gia xuất xứ/quốc tịch.
- `last_affiliation`: Nơi trực thuộc gần nhất trước khi gia nhập NBA.
- `height`: Chiều cao theo hệ đo lường Mỹ (Feet-Inches, ví dụ: `6-10` nghĩa là 6 feet 10 inches ~ 208 cm).
- `weight`: Cân nặng tính bằng Pounds (lbs). Muốn đổi sang kg: `lbs * 0.453592`.
- `season_exp`: Số năm kinh nghiệm thi đấu tại NBA.
- `jersey`: Số áo thi đấu (ví dụ: 23, 30).
- `position`: Vị trí thi đấu trên sân (`Guard` - Hậu vệ, `Forward` - Tiền đạo, `Center` - Trung phong).
- `rosterstatus`: Tình trạng trong danh sách đội (`Active` - Đang đăng ký, `Inactive` - Ngoài danh sách).
- `games_played_current_season_flag`: Cờ đánh dấu có thi đấu ở mùa giải hiện tại hay không (`Y`/`N`).
- `team_id`, `team_name`, `team_abbreviation`, `team_code`, `team_city`: Thông tin đội bóng chủ quản gần nhất.
- `playercode`: Mã định danh nội bộ hệ thống NBA.
- `from_year`: Năm bắt đầu ra mắt tại NBA (Rookie year).
- `to_year`: Năm cuối cùng còn thi đấu tại NBA.
- `dleague_flag`: Cờ đánh dấu từng thi đấu tại giải hạng dưới (D-League / G-League).
- `nba_flag`: Cờ xác nhận đã chính thức ra sân tại NBA.
- `games_played_flag`: Đã từng chơi trận nào hay chưa.
- `draft_year`: Năm được tuyển chọn qua kỳ Draft.
- `draft_round`: Vòng tuyển chọn (Vòng 1, Vòng 2...).
- `draft_number`: Số thứ tự lượt chọn (Pick #1, #2...).
- `greatest_75_flag`: Đánh dấu cầu thủ có lọt vào danh sách "Top 75 cầu thủ vĩ đại nhất lịch sử NBA" hay không (`Y`/`N`).

#### 3. `draft_history.csv` (7,990 dòng, 14 cột) — Lịch sử tuyển chọn tân binh
- `person_id`: Mã định danh cầu thủ.
- `player_name`: Tên cầu thủ khi được Draft.
- `season`: Mùa giải diễn ra kỳ tuyển chọn tân binh (năm Draft).
- `round_number`: Số thứ tự vòng tuyển chọn (Round 1, 2...).
- `round_pick`: Thứ tự lượt chọn trong vòng đó.
- `overall_pick`: Thứ tự lượt chọn tổng thể trên toàn kỳ Draft (Pick #1 là trạng nguyên Draft).
- `draft_type`: Loại hình tuyển chọn (thường là `Draft`).
- `team_id`, `team_city`, `team_name`, `team_abbreviation`: Đội bóng NBA đã dùng lượt chọn để sở hữu cầu thủ.
- `organization`: Trường đại học hoặc CLB quốc tế mà cầu thủ thi đấu trước kỳ Draft.
- `organization_type`: Phân loại tổ chức (`College/University`, `International club`, `High School`...).
- `player_profile_flag`: Đã có hồ sơ cá nhân hoàn chỉnh trên hệ thống hay chưa.

#### 4. `draft_combine_stats.csv` (1,202 dòng, 47 cột) — Chỉ số kiểm tra thể lực tân binh
Ghi lại kết quả các bài kiểm tra thể chất tại sự kiện NBA Draft Combine hàng năm:
- `season`, `player_id`, `player_name`, `position`: Năm kiểm tra và thông tin cầu thủ.
- `height_wo_shoes`, `height_wo_shoes_ft_in`: Chiều cao khi không đi giày (Inches và Feet-Inches).
- `height_w_shoes`, `height_w_shoes_ft_in`: Chiều cao khi đi giày thi đấu.
- `weight`: Cân nặng tại kỳ kiểm tra (lbs).
- `wingspan`, `wingspan_ft_in`: Sải tay (sải cánh đo từ đầu ngón tay trái sang ngón tay phải) — chỉ số cực kỳ quan trọng trong bóng rổ.
- `standing_reach`, `standing_reach_ft_in`: Tầm với đứng (tầm với chạm cao nhất khi đứng thẳng hai chân chạm đất).
- `body_fat_pct`: Tỷ lệ phần trăm mỡ cơ thể (Body Fat %).
- `hand_length`, `hand_width`: Chiều dài và độ rộng bàn tay.
- `standing_vertical_leap`: Độ cao bật nhảy tại chỗ không lấy đà (Inches).
- `max_vertical_leap`: Độ cao bật nhảy tối đa có bước đà (Inches).
- `lane_agility_time`: Thời gian hoàn thành bài chạy né cọc đổi hướng phòng ngự quanh khu vực hình thang (giây) — đo độ nhanh nhẹn.
- `modified_lane_agility_time`: Thời gian bài chạy đổi hướng biến thể.
- `three_quarter_sprint`: Thời gian chạy nước rút 3/4 chiều dài sân bóng (giây) — đo tốc độ bứt tốc.
- `bench_press`: Số lần đẩy tạ nằm mức chuẩn 185 lbs (~84 kg) — đo sức mạnh phần trên cơ thể.
- Các cột `spot_*` (từ cột 25 đến 39): Tỷ lệ ném rổ trúng đích tại các vị trí cố định trên sân (góc 0 độ, 45 độ, đỉnh vòng cung) theo cự ly 15 feet, cự ly đại học (college), cự ly NBA.
- Các cột `off_drib_*` (cột 40 đến 45): Tỷ lệ ném rổ sau khi dẫn bóng di chuyển.
- Các cột `on_move_*` (cột 46, 47): Tỷ lệ ném rổ khi đang chạy chỗ không bóng.

---

### NHÓM 2: CÁC FILE VỀ ĐỘI BÓNG (TEAM DATA)

#### 5. `team.csv` (30 dòng, 7 cột) — Danh mục 30 đội bóng hiện tại
- `id`: Mã định danh đội bóng (Primary Key).
- `full_name`: Tên đầy đủ của đội (ví dụ: Los Angeles Lakers, Golden State Warriors).
- `abbreviation`: Tên viết tắt 3 chữ cái (LAL, GSW, BOS, MIA...).
- `nickname`: Biệt danh của đội (Lakers, Warriors, Celtics...).
- `city`: Thành phố đóng quân.
- `state`: Bang tại Mỹ (hoặc Ontario cho Toronto).
- `year_founded`: Năm thành lập đội bóng.

#### 6. `team_details.csv` (25 dòng, 14 cột) — Thông tin chi tiết đội & Nhà thi đấu
- `team_id`: Khóa ngoại trỏ đến `team.id`.
- `abbreviation`, `nickname`, `city`, `yearfounded`: Các thông tin lặp lại từ team.csv.
- `arena`: Tên nhà thi đấu / Sân vận động sân nhà (ví dụ: Crypto.com Arena, Chase Center, TD Garden).
- `arenacapacity`: Sức chứa khán giả tối đa của nhà thi đấu.
- `owner`: Chủ sở hữu / Tỷ phú sở hữu đội bóng.
- `generalmanager`: Tổng giám đốc điều hành chuyên môn (GM).
- `headcoach`: Huấn luyện viên trưởng đương nhiệm.
- `dleagueaffiliation`: Đội bóng liên kết ở giải phát triển G-League.
- `facebook`, `instagram`, `twitter`: Đường dẫn mạng xã hội chính thức.

#### 7. `team_history.csv` (52 dòng, 5 cột) — Lịch sử đổi tên và địa điểm
Ghi nhận các giai đoạn di dời thành phố hoặc đổi biệt danh trong quá khứ của các đội:
- `team_id`: Mã đội bóng.
- `city`, `nickname`: Thành phố và tên gọi tại giai đoạn lịch sử đó (ví dụ: Minneapolis Lakers trước khi chuyển về Los Angeles).
- `year_founded`: Năm bắt đầu sử dụng tên gọi/địa điểm này.
- `year_active_till`: Năm kết thúc giai đoạn này.

#### 8. `team_info_common.csv` (0 dòng, 26 cột)
File rỗng (chỉ có tiêu đề cột), là cấu trúc chuẩn bị sẵn của NBA API cho thống kê mùa giải nhưng không có bản ghi dữ liệu.

---

### NHÓM 3: CÁC FILE VỀ TRẬN ĐẤU (GAME DATA)

#### 9. `game.csv` (65,698 dòng, 55 cột) — Bảng trận đấu cốt lõi
Mỗi dòng lưu thông số tổng hợp của 1 trận đấu cho cả đội Chủ Nhà (`_home`) và Khách (`_away`).
- `season_id`: Mã mùa giải (ví dụ: 22022 = Mùa giải 2022-23).
- `game_id`: Mã định danh trận đấu duy nhất.
- `game_date`: Ngày giờ diễn ra trận đấu.
- `season_type`: Loại hình mùa giải (`Regular Season` - Mùa giải thường, `Playoffs` - Vòng đấu loại trực tiếp, `All-Star` - Trận toàn sao).
- **Thông tin Đội Nhà (`_home`):**
  - `team_id_home`, `team_abbreviation_home`, `team_name_home`: Đội chủ nhà.
  - `matchup_home`: Chuỗi đối đầu (vd: `LAL vs. GSW`).
  - `wl_home`: Kết quả (`W` = Thắng, `L` = Thua).
  - `min`: Số phút thi đấu của trận (chuẩn là 240 phút = 4 hiệp x 12 phút cho cả 5 người, nếu có hiệp phụ thì nhiều hơn).
  - `pts_home`: Tổng điểm đội nhà ghi được.
  - `plus_minus_home`: Hiệu số điểm bàn thắng/bại (`pts_home - pts_away`).
  - `fgm_home` / `fga_home` / `fg_pct_home`: Số cú ném 2+3 điểm trúng đích / Tổng số lần ném / Tỷ lệ trúng (Field Goal).
  - `fg3m_home` / `fg3a_home` / `fg3_pct_home`: Số cú ném 3 điểm trúng / Tổng lần ném 3 / Tỷ lệ ném 3 trúng.
  - `ftm_home` / `fta_home` / `ft_pct_home`: Số quả ném phạt trúng / Tổng số lần ném phạt / Tỷ lệ ném phạt trúng.
  - `oreb_home`: Bắt bóng bật bảng bên tấn công (Offensive Rebounds).
  - `dreb_home`: Bắt bóng bật bảng bên phòng thủ (Defensive Rebounds).
  - `reb_home`: Tổng số lần bắt bóng bật bảng (`oreb + dreb`).
  - `ast_home`: Số pha chuyền bóng kiến tạo thành bàn (Assists).
  - `stl_home`: Số lần cướp bóng từ tay đối phương (Steals).
  - `blk_home`: Số pha cản phá/chắn bóng đối phương ném (Blocks).
  - `tov_home`: Số lần làm mất bóng (Turnovers).
  - `pf_home`: Số lần phạm lỗi cá nhân (Personal Fouls).
  - `video_available_home`: Cờ video trận đấu có sẵn trên NBA archive hay không.
- **Thông tin Đội Khách (`_away`):**
  - Tương tự toàn bộ các chỉ số trên nhưng áp dụng cho đội khách (`team_id_away`, `pts_away`, `fgm_away`, `reb_away`...).

#### 10. `game_info.csv` (58,053 dòng, 4 cột) — Thông tin vận hành trận đấu
- `game_id`: Mã trận đấu.
- `game_date`: Ngày thi đấu.
- `attendance`: Lượng khán giả trực tiếp đến sân theo dõi trận đấu.
- `game_time`: Tổng thời gian thực tế diễn ra trận đấu (ví dụ: `2:15` nghĩa là 2 giờ 15 phút).

#### 11. `game_summary.csv` (58,110 dòng, 14 cột) — Tóm lược tiến trình trận đấu
- `game_id`: Mã trận đấu.
- `game_date_est`: Ngày thi đấu theo múi giờ chuẩn miền Đông nước Mỹ (EST).
- `game_sequence`: Thứ tự trận đấu diễn ra trong ngày.
- `game_status_id`: Mã trạng thái (`1` = Chưa đấu, `2` = Đang đấu, `3` = Đã kết thúc).
- `game_status_text`: Chuỗi mô tả trạng thái (thường là `Final`).
- `gamecode`: Mã kết hợp ngày và 2 đội (vd: `20221018/PHIBOS`).
- `home_team_id`, `visitor_team_id`: Mã đội nhà và đội khách.
- `season`: Năm mùa giải (ví dụ: 2022).
- `live_period`: Hiệp đấu hiện tại khi cập nhật (4 = hết 4 hiệp chính, 5 = có hiệp phụ OT1).
- `live_pc_time`: Thời gian còn lại trên đồng hồ thi đấu.
- `natl_tv_broadcaster_abbreviation`: Kênh truyền hình quốc gia phát sóng trực tiếp trận đấu (ESPN, TNT, ABC, NBA TV...).
- `live_period_time_bcast`: Chuỗi hiển thị phát sóng.
- `wh_status`: Trạng thái xử lý dữ liệu của kho lưu trữ.

#### 12. `line_score.csv` (58,053 dòng, 43 cột) — Điểm số chi tiết theo từng hiệp
Lưu điểm số ghi được trong từng hiệp đấu riêng biệt của 2 đội:
- `game_id`: Mã trận đấu.
- `pts_qtr1_home` đến `pts_qtr4_home`: Điểm số đội nhà ghi được ở Hiệp 1, Hiệp 2, Hiệp 3, Hiệp 4.
- `pts_ot1_home` đến `pts_ot10_home`: Điểm số đội nhà ghi được ở các hiệp phụ (Overtime 1 đến 10) nếu trận đấu bị hòa.
- `pts_home`: Tổng điểm chung cuộc của đội nhà.
- Tương ứng các cột phía đội khách: `pts_qtr1_away` đến `pts_qtr4_away`, `pts_ot1_away` đến `pts_ot10_away`, `pts_away`.

#### 13. `other_stats.csv` (28,271 dòng, 26 cột) — Chỉ số chiến thuật nâng cao của trận đấu
(Dữ liệu có từ mùa giải 2000-01 trở đi khi NBA bắt đầu theo dõi chuyên sâu)
- `game_id`: Mã trận đấu.
- `pts_paint_home` / `_away`: Điểm ghi được trong "khu vực hình chữ nhật dưới rổ" (Points in the Paint) — thể hiện sức mạnh nội tuyến.
- `pts_2nd_chance_home` / `_away`: Điểm ghi từ tình huống cơ hội thứ hai (sau khi bắt được offensive rebound).
- `pts_fb_home` / `_away`: Điểm ghi từ các đợt phản công nhanh (Fast Break Points).
- `pts_off_to_home` / `_away`: Điểm ghi được tận dụng từ sai lầm mất bóng của đối phương (Points off Turnovers).
- `largest_lead_home` / `_away`: Khoảng cách dẫn điểm lớn nhất mà đội từng tạo ra trong trận đấu.
- `lead_changes`: Số lần đổi vị trí dẫn điểm giữa 2 đội (chỉ số đo độ kịch tính).
- `times_tied`: Số lần hai đội bị san bằng điểm số hòa nhau.
- `team_turnovers_home` / `_away`: Số lần mất bóng lỗi cấp toàn đội (như lỗi 24 giây).
- `total_turnovers_home` / `_away`: Tổng số lần mất bóng (cá nhân + đội).
- `team_rebounds_home` / `_away`: Tổng số lần bắt bóng bật bảng cấp toàn đội.

---

### NHÓM 4: CÁC FILE BỔ TRỢ & SỰ KIỆN CHI TIẾT (AUXILIARY & EVENT DATA)

#### 14. `inactive_players.csv` (110,191 dòng, 9 cột) — Cầu thủ vắng mặt trong trận
Ghi lại danh sách các cầu thủ không được đăng ký thi đấu trong từng trận (do chấn thương, chiến thuật hoặc kỷ luật):
- `game_id`: Trận đấu vắng mặt.
- `player_id`, `first_name`, `last_name`, `jersey_num`: Cầu thủ vắng mặt.
- `team_id`, `team_city`, `team_name`, `team_abbreviation`: Đội bóng mà cầu thủ đó trực thuộc.

#### 15. `officials.csv` (70,971 dòng, 5 cột) — Trọng tài điều hành trận đấu
Ghi nhận tổ trọng tài bắt chính trong từng trận:
- `game_id`: Mã trận đấu.
- `official_id`: Mã định danh trọng tài.
- `first_name`, `last_name`: Họ tên trọng tài.
- `jersey_num`: Số áo của trọng tài.

#### 16. `play_by_play.csv` (13,592,899 dòng, 34 cột, ~2.15 GB) — Nhật ký chi tiết từng pha bóng
File dữ liệu khổng lồ cấp độ hành vi (Event-level / Clickstream equivalent in Sports):
- `game_id`: Mã trận đấu.
- `eventnum`: Số thứ tự của pha bóng trong trận (tăng dần từ 1 đến vài trăm).
- `eventmsgtype`: Phân loại hành động (1 = Ném vào rổ, 2 = Ném hỏng, 3 = Ném phạt, 4 = Bắt bóng bật bảng, 5 = Mất bóng, 6 = Phạm lỗi...).
- `eventmsgactiontype`: Chi tiết động tác kỹ thuật (Dunk, Layup, Step-back jump shot, Fadeaway...).
- `period`: Hiệp đấu diễn ra sự kiện (Hiệp 1, 2, 3, 4 hoặc OT).
- `pctimestring`: Đồng hồ thời gian thi đấu còn lại của hiệp (ví dụ: `11:45`).
- `homedescription`: Lời tường thuật hành động nếu thuộc về đội chủ nhà (vd: *"James 3pt Shot: Made"*).
- `neutraldescription`: Tường thuật sự kiện trung tính (vd: bắt đầu hiệp, hết giờ).
- `visitordescription`: Lời tường thuật hành động nếu thuộc về đội khách.
- `score`: Tỷ số hiện tại sau pha bóng.
- `scoremargin`: Cách biệt điểm số tại thời điểm đó (vd: `+2`, `TIE`).
- `player1_id`, `player1_name`, `player1_team_id`...: Cầu thủ trực tiếp thực hiện hành vi chính (người ném bóng, người phạm lỗi).
- `player2_id`...: Cầu thủ liên quan thứ hai (người kiến tạo, người bị phạm lỗi, người cướp bóng).
- `player3_id`...: Cầu thủ liên quan thứ ba (người chắn bóng, người bị cướp bóng).
