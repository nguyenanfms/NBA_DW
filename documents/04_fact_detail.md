# THIẾT KẾ BẢNG FACT TINH GỌN: `fact_team_game`
## (Data Warehouse phục vụ Phân tích Kết quả Trận đấu NBA)

Tài liệu này đặc tả chi tiết **22 cột cốt lõi tuyệt đối** của bảng Fact trung tâm `fact_team_game`.  
Thiết kế tuân thủ nghiêm ngặt nguyên tắc **Ralph Kimball Dimensional Modeling**:
> **"Mỗi cột được chọn đưa vào Fact đều phải có chức năng rõ ràng và trả lời trực tiếp cho ít nhất một câu hỏi phân tích / bài toán nghiệp vụ cụ thể. Loại bỏ 100% các cột dư thừa không dùng đến."**

---

## 1. TỔNG QUAN VỀ BẢNG FACT

| Thuộc tính | Giá trị |
|---|---|
| **Tên bảng** | `fact_team_game` |
| **Hạt dữ liệu (Grain)** | Hiệu suất thi đấu của **1 đội bóng** trong **1 trận đấu** |
| **Số dòng ước tính** | ~131,284 dòng (65,642 trận x 2 đội sau khi Unpivot) |
| **Số lượng cột** | **22 cột** (Tinh gọn, loại bỏ hoàn toàn các cột rác/dư thừa) |
| **Nguồn nạp dữ liệu** | `dataset/processed/games_merged.csv` |
| **Liên kết mở rộng** | Bảng cầu nối `player_game` liên kết qua `game_id` để biết danh sách các cầu thủ tham gia trận đấu |

---

## 2. CHI TIẾT CHỨC NĂNG TỪNG CỘT & CÂU HỎI TRUY VẤN MINH CHỨNG

### NHÓM 1: CÁC KHÓA ĐỊNH DANH & LIÊN KẾT CHIỀU (KEYS) (Cột 1 – 7)

#### 1. `fact_id` (Kiểu: BIGINT, PK)
- **Chức năng:** Khóa chính thay thế (Surrogate Key) duy nhất của từng dòng trong bảng Fact. Tự động tăng (`IDENTITY(1,1)`) khi nạp dữ liệu.
- **Ứng dụng:** Định danh duy nhất từng bản ghi, tối ưu hóa việc đánh chỉ mục (Clustered Index) và quản lý lưu trữ vật lý trong DBMS.

#### 2. `game_id` (Kiểu: NVARCHAR(30), Degenerate Dimension)
- **Chức năng:** Khóa thoái hóa (Degenerate Dimension) lưu mã trận đấu gốc từ hệ thống NBA. Không tạo bảng Dim riêng vì nó không có thuộc tính mô tả bổ sung nào.
- **Vai trò đặc biệt:** Là điểm tựa để kết nối (Join) với bảng cầu nối `player_game` để mở rộng phân tích các cầu thủ tham gia trận đấu.
- **Câu hỏi truy vấn chứng minh:**
  > *"Tìm toàn bộ thông số chi tiết của trận Chung kết NBA Finals Game 7 năm 2016 giữa Cleveland Cavaliers và Golden State Warriors và danh sách các cầu thủ ra sân của hai đội?"*  
  *(Dùng `game_id` để kết nối Fact và bảng `player_game`).*

#### 3. `date_key` (Kiểu: INT, FK $\rightarrow$ `dim_date.date_key`)
- **Chức năng:** Khóa ngoại trỏ đến chiều thời gian lịch `dim_date` theo định dạng số `YYYYMMDD` (ví dụ: `20230512`).
- **Câu hỏi truy vấn chứng minh:**
  > *"Các trận đấu diễn ra vào ngày cuối tuần (is_weekend = 1) có điểm số trung bình và hiệu suất thi đấu khác biệt thế nào so với các ngày giữa tuần?"*

#### 4. `season_id` (Kiểu: INT, FK $\rightarrow$ `dim_season.season_id`)
- **Chức năng:** Khóa ngoại trỏ đến chiều mùa giải và kỷ nguyên thi đấu `dim_season` (sử dụng Natural Key trực tiếp từ NBA, vd: `22022`).
- **Câu hỏi truy vấn chứng minh:**
  > *"Số quả ném 3 điểm trung bình mỗi trận tăng trưởng như thế nào qua từng mùa giải (Season) và qua 4 Kỷ nguyên (Era: Early, Jordan, Pace & Space, 3-Point Revolution)?"*

#### 5. `team_id` (Kiểu: BIGINT, FK $\rightarrow$ `dim_team.team_id`)
- **Chức năng:** Khóa ngoại trỏ đến đội bóng đang được phân tích (Đội chủ thể của dòng dữ liệu - sử dụng Natural Key chính thức của NBA).
- **Câu hỏi truy vấn chứng minh:**
  > *"Đội bóng nào (Team), Phân khu nào (Division) và Miền nào (Conference) sở hữu tỷ lệ thắng cao nhất toàn giải trong 10 năm qua?"*

#### 6. `opponent_id` (Kiểu: BIGINT, FK $\rightarrow$ `dim_team.team_id` — Role-Playing Dimension)
- **Chức năng:** Khóa ngoại trỏ đến đội đối thủ trong trận đấu (Áp dụng kỹ thuật Role-Playing Dimension tái sử dụng bảng `dim_team`).
- **Câu hỏi truy vấn chứng minh:**
  > *"Thành tích đối đầu trực tiếp (Head-to-head Rivalry) lịch sử giữa Los Angeles Lakers và Boston Celtics trong các giai đoạn Playoffs là bao nhiêu trận thắng/thua?"*

#### 7. `arena_key` (Kiểu: INT, FK $\rightarrow$ `dim_arena.arena_key`)
- **Chức năng:** Khóa ngoại trỏ đến nhà thi đấu nơi trận đấu diễn ra (Surrogate Key).
- **Câu hỏi truy vấn chứng minh:**
  > *"Đội bóng thi đấu tại nhà thi đấu nào thì đạt hiệu suất ném rổ sân nhà (Home FG%) cao nhất?"*

---

### NHÓM 2: CỜ TRẠNG THÁI & KẾT QUẢ TRẬN ĐẤU (FLAGS & TARGETS) (Cột 8 – 9)

#### 8. `is_home` (Kiểu: TINYINT, Giá trị: 0 hoặc 1)
- **Chức năng:** Phân biệt vị thế thi đấu: `1` = Đội thi đấu trên sân nhà (Home), `0` = Đội thi đấu trên sân khách (Away).
- **Câu hỏi truy vấn chứng minh:**
  > *"Yếu tố lợi thế sân nhà (Home Court Advantage) đem lại mức tăng bao nhiêu % tỷ lệ thắng cho từng đội bóng?"*

#### 9. `is_win` (Kiểu: TINYINT, Giá trị: 0 hoặc 1)
- **Chức năng:** **MỤC TIÊU CỐT LÕI CỦA ĐỒ ÁN** — Ghi nhận kết quả trận đấu: `1` = Chiến thắng, `0` = Thất bại.
- **Câu hỏi truy vấn chứng minh:**
  > *"Tỷ lệ thắng (Win Rate %) của đội bóng qua từng tháng trong năm: `SUM(is_win) * 100.0 / COUNT(*)`?"*  
  *(Đồng thời đây chính là nhãn Target cho bài toán Machine Learning: Dự đoán kết quả Thắng/Thua).*

---

### NHÓM 3: CHỈ SỐ ĐIỂM SỐ & HIỆU SỐ (SCORING MEASURES) (Cột 10 – 12)

#### 10. `pts` (Kiểu: FLOAT, Additive Measure)
- **Chức năng:** Tổng số điểm đội bóng ghi được trong trận đấu.
- **Câu hỏi truy vấn chứng minh:**
  > *"Điểm số trung bình mỗi trận (Points Per Game - PPG) của từng đội bóng qua các mùa giải: `AVG(pts)`?"*

#### 11. `pts_opponent` (Kiểu: FLOAT, Additive Measure)
- **Chức năng:** Tổng số điểm đối thủ ghi được vào rổ của đội nhà (= Điểm thủng lưới).
- **Câu hỏi truy vấn chứng minh:**
  > *"Đội bóng nào sở hữu hàng phòng ngự vững chắc nhất giải đấu (để đối thủ ghi ít điểm trung bình nhất mỗi trận: `AVG(pts_opponent)`)?"*

#### 12. `plus_minus` (Kiểu: INT, Additive Measure)
- **Chức năng:** Hiệu số điểm bàn thắng/bại của trận đấu = `pts - pts_opponent`. Giá trị dương nghĩa là thắng cách biệt, âm nghĩa là thua cách biệt.
- **Câu hỏi truy vấn chứng minh:**
  > *"Hiệu số điểm trung bình của các đội thuộc Miền Tây (Western Conference) có thực sự vượt trội hơn so với Miền Đông (Eastern Conference) hay không?"*

---

### NHÓM 4: CHỈ SỐ HIỆU SUẤT NÉM RỔ & DỨT ĐIỂM (SHOOTING MEASURES) (Cột 13 – 16)
*(Loại bỏ các cột tỷ lệ `%` tính sẵn vì là Semi-Additive vi phạm chuẩn Kimball; lưu cặp Tử số / Mẫu số để tính tỷ lệ chính xác trong SQL)*

#### 13. `fgm` (Kiểu: FLOAT, Additive Measure)
- **Chức năng:** Field Goals Made — Tổng số cú ném rổ 2 điểm và 3 điểm trúng đích.

#### 14. `fga` (Kiểu: FLOAT, Additive Measure)
- **Chức năng:** Field Goals Attempted — Tổng số lần thực hiện cú ném rổ (bao gồm cả trượt).
- **Câu hỏi truy vấn chứng minh:**
  > *"Tỷ lệ ném rổ tổng thể của toàn giải đấu qua từng mùa giải: `SUM(fgm) * 100.0 / SUM(fga)` thay đổi như thế nào?"*

#### 15. `fg3m` (Kiểu: FLOAT, Additive Measure)
- **Chức năng:** 3-Point Field Goals Made — Số quả ném 3 điểm trúng đích.
- **Câu hỏi truy vấn chứng minh:**
  > *"Đội bóng nào ghi được nhiều điểm từ vạch 3 điểm nhất mùa giải: `SUM(fg3m) * 3`?"*

#### 16. `fg3a` (Kiểu: FLOAT, Additive Measure)
- **Chức năng:** 3-Point Field Goals Attempted — Tổng số lần ném 3 điểm.
- **Câu hỏi truy vấn chứng minh:**
  > *"Tỷ lệ ném 3 điểm thành công: `SUM(fg3m) * 100.0 / SUM(fg3a)` của các đội khi thi đấu sân nhà vs sân khách chênh lệch thế nào?"*

---

### NHÓM 5: CHỈ SỐ KIỂM SOÁT BÓNG & PHỐI HỢP (BALL CONTROL & TEAMPLAY) (Cột 17 – 19)

#### 17. `reb` (Kiểu: FLOAT, Additive Measure)
- **Chức năng:** Total Rebounds — Tổng số lần tranh chấp bắt bóng bật bảng thành công (cả phòng ngự lẫn tấn công).
- **Câu hỏi truy vấn chứng minh:**
  > *"Khả năng kiểm soát bảng rổ có quyết định thắng thua? Các đội có chỉ số Rebounds vượt trội đối thủ có tỷ lệ thắng lớn hơn 70% hay không?"*

#### 18. `ast` (Kiểu: FLOAT, Additive Measure)
- **Chức năng:** Assists — Số pha chuyền bóng trực tiếp tạo thành bàn (kiến tạo). Đo lường mức độ phối hợp đồng đội so với lối chơi cá nhân độc lập (ISO).
- **Câu hỏi truy vấn chứng minh:**
  > *"Mối tương quan giữa lối chơi đồng đội (số pha kiến tạo trung bình `AVG(ast)`) và xác suất lọt vào vòng chung kết Playoffs của các đội?"*

#### 19. `tov` (Kiểu: FLOAT, Additive Measure)
- **Chức năng:** Turnovers — Số lần để mất quyền kiểm soát bóng vào tay đối phương (sai lầm cá nhân/lỗi chuyền). Chỉ số này càng thấp càng tốt.
- **Câu hỏi truy vấn chứng minh:**
  > *"Số lần làm mất bóng trung bình trong các trận THUA cao hơn bao nhiêu so với các trận THẮNG của từng đội bóng?"*

---

### NHÓM 6: CHỈ SỐ CHIẾN THUẬT CHUYÊN SÂU (TACTICAL MEASURES) (Cột 20 – 21)

#### 20. `pts_paint` (Kiểu: FLOAT, Additive Measure)
- **Chức năng:** Points in the Paint — Số điểm ghi được trong khu vực cận rổ (khu vực hình chữ nhật dưới cột rổ). Đại diện cho sức mạnh tấn công nội tuyến và thể hình.
- **Câu hỏi truy vấn chứng minh:**
  > *"Chiến thuật nào hiệu quả hơn: Đội bóng tập trung ghi điểm cận rổ (`pts_paint`) hay đội bóng tập trung ném 3 điểm ngoài vòng cung (`fg3m * 3`) có tỷ lệ thắng cao hơn?"*

#### 21. `pts_fast_break` (Kiểu: FLOAT, Additive Measure)
- **Chức năng:** Fast Break Points — Điểm ghi được từ các đợt phản công nhanh chớp nhoáng khi đối thủ chưa kịp lui về phòng ngự. Thể hiện lối chơi tốc độ (Pace).
- **Câu hỏi truy vấn chứng minh:**
  > *"Đội bóng nào sở hữu lối chơi chuyển đổi trạng thái (Transition/Fast Break) sắc bén nhất giải đấu qua chỉ số `AVG(pts_fast_break)`?"*

---

### NHÓM 7: SỐ ĐO HẰNG SỐ ĐẾM (COUNTING MEASURE) (Cột 22)

#### 22. `game_count` (Kiểu: TINYINT, Luôn luôn = 1)
- **Chức năng:** Hằng số luôn có giá trị là `1` trên mọi dòng Fact.
- **Câu hỏi truy vấn chứng minh:**
  - Đếm số trận đã đấu của 1 đội bóng: `SUM(game_count)`.
  - Đếm tổng số trận đấu diễn ra trên toàn giải: `SUM(game_count) / 2` (chia 2 vì 1 trận được unpivot thành 2 dòng Fact).
  - Giúp việc tính toán các chỉ số trung bình và tỷ lệ phần trăm trong SQL OLAP cực kỳ nhanh và chuẩn xác mà không cần dùng hàm `COUNT(DISTINCT)`.
