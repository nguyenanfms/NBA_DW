# 1.3. CÁC CÂU TRUY VẤN PHÂN TÍCH ĐA CHIỀU (OLAP QUERIES)
## Đề tài: Xây dựng Kho dữ liệu và Hệ thống OLAP phân tích kết quả trận đấu giải bóng rổ NBA

Tài liệu này tổng hợp **15 câu truy vấn phân tích đa chiều** được thiết kế bám sát mô hình Star Schema và bảng cầu nối `player_game` (gồm bảng Fact `fact_team_game`, bảng cầu nối `player_game`, và 5 bảng Dimension: `dim_date`, `dim_season`, `dim_team`, `dim_arena`, `dim_player`).  
Các câu truy vấn bao phủ đầy đủ các thao tác phân tích OLAP: **Roll-up (cuộn gộp), Drill-down (khoan sâu), Slice & Dice (cắt lát), và Pivot (xoay chiều)** phục vụ trực tiếp cho mục tiêu đánh giá kết quả trận đấu, chiến thuật đội bóng và đóng góp của cầu thủ.

---

### 1.3.1. Liệt kê top 5 đội bóng có tỷ lệ chiến thắng cao nhất ở Miền Tây (Western Conference) trong mùa giải chính thức (Regular Season) năm 2022 theo thứ tự giảm dần.
* **Mục tiêu nghiệp vụ:** Xác định các đội hạt giống hàng đầu dẫn đầu bảng xếp hạng miền Tây để phân tích phong độ trước khi bước vào vòng đấu loại trực tiếp (Playoffs).
* **Thao tác OLAP:** *Slice* (`conference = 'Western Conference'`, `season_type = 'Regular Season'`), *Dice* (`year_number = 2022`), *Roll-up* theo đội bóng, *Order By* tỷ lệ thắng.
* **Minh họa truy vấn SQL:**
```sql
SELECT TOP 5 
    t.full_name,
    COUNT(*) AS total_games,
    SUM(f.is_win) AS total_wins,
    CAST(SUM(f.is_win) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS win_rate_pct
FROM dbo.fact_team_game f
JOIN dbo.dim_team t ON f.team_id = t.team_id
JOIN dbo.dim_season s ON f.season_id = s.season_id
JOIN dbo.dim_date d ON f.date_key = d.date_key
WHERE t.conference = 'Western Conference'
  AND s.season_type = 'Regular Season'
  AND d.year_number = 2022
GROUP BY t.full_name
ORDER BY win_rate_pct DESC;
```

---

### 1.3.2. Thống kê điểm số trung bình và hiệu số điểm trung bình của các đội bóng thuộc 3 phân khu Pacific, Atlantic, Southeast trong các tháng 1, tháng 2, tháng 3 năm 2023.
* **Mục tiêu nghiệp vụ:** So sánh sức mạnh tấn công và mức độ chênh lệch thực lực giữa các phân khu (Divisions) trong giai đoạn giữa mùa giải (thời điểm cạnh tranh căng thẳng nhất).
* **Thao tác OLAP:** *Slice* (`division IN ('Pacific', 'Atlantic', 'Southeast')`, `month_number IN (1, 2, 3)`), *Dice* (`year_number = 2023`), *Roll-up* tính `AVG(pts)` và `AVG(plus_minus)`.
* **Minh họa truy vấn SQL:**
```sql
SELECT 
    t.division,
    d.month_name,
    ROUND(AVG(f.pts), 2) AS avg_points,
    ROUND(AVG(f.plus_minus), 2) AS avg_plus_minus
FROM dbo.fact_team_game f
JOIN dbo.dim_team t ON f.team_id = t.team_id
JOIN dbo.dim_date d ON f.date_key = d.date_key
WHERE t.division IN ('Pacific', 'Atlantic', 'Southeast')
  AND d.year_number = 2023
  AND d.month_number IN (1, 2, 3)
GROUP BY t.division, d.month_name, d.month_number
ORDER BY t.division, d.month_number;
```

---

### 1.3.3. Thống kê tỷ lệ chiến thắng trung bình của các đội bóng khi thi đấu trên sân nhà so với khi thi đấu trên sân khách tại hai miền Đông và Tây trong mùa giải 2022-23.
* **Mục tiêu nghiệp vụ:** Đánh giá mức độ ảnh hưởng của yếu tố "Lợi thế sân nhà" (Home Court Advantage) đến kết quả thắng/thua của các đội bóng ở từng liên đoàn.
* **Thao tác OLAP:** *Drill-down* theo `conference` và `is_home`, *Roll-up* tính `SUM(is_win) * 100.0 / COUNT(*)`.
* **Minh họa truy vấn SQL:**
```sql
SELECT 
    t.conference,
    CASE WHEN f.is_home = 1 THEN 'Home' ELSE 'Away' END AS court_location,
    COUNT(*) AS total_games,
    CAST(SUM(f.is_win) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS win_rate_pct
FROM dbo.fact_team_game f
JOIN dbo.dim_team t ON f.team_id = t.team_id
JOIN dbo.dim_season s ON f.season_id = s.season_id
WHERE s.season_display = '2022-23'
GROUP BY t.conference, f.is_home
ORDER BY t.conference, f.is_home DESC;
```

---

### 1.3.4. Thống kê 10 đội bóng có số pha kiến tạo trung bình cao nhất toàn giải và tỷ lệ chiến thắng tương ứng của các đội bóng đó trong giai đoạn Playoffs.
* **Mục tiêu nghiệp vụ:** Kiểm chứng nhận định chiến thuật: Liệu lối chơi phối hợp đồng đội (Assists cao) có tỷ lệ thuận với khả năng giành chiến thắng ở những trận đấu loại trực tiếp căng thẳng hay không?
* **Thao tác OLAP:** *Slice* (`season_type = 'Playoffs'`), *Roll-up* tính `AVG(ast)` và `Win Rate`, *Top 10* theo `AVG(ast)`.
* **Minh họa truy vấn SQL:**
```sql
SELECT TOP 10 
    t.full_name,
    COUNT(*) AS playoff_games,
    ROUND(AVG(f.ast), 2) AS avg_assists,
    CAST(SUM(f.is_win) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS win_rate_pct
FROM dbo.fact_team_game f
JOIN dbo.dim_team t ON f.team_id = t.team_id
JOIN dbo.dim_season s ON f.season_id = s.season_id
WHERE s.season_type = 'Playoffs'
GROUP BY t.full_name
ORDER BY avg_assists DESC;
```

---

### 1.3.5. Thống kê số lượng quả ném 3 điểm thành công trung bình mỗi trận của toàn giải đấu qua 4 kỷ nguyên thi đấu (Early Pioneer, Jordan Era, Pace & Space, 3-Point Revolution).
* **Mục tiêu nghiệp vụ:** Đo lường sự chuyển dịch mang tính lịch sử của bóng rổ hiện đại (Cuộc cách mạng ném 3 điểm - 3-Point Revolution) qua các thời kỳ phát triển của NBA.
* **Thao tác OLAP:** *Roll-up* theo cấp bậc cao nhất `dim_season.era_name`, tính `AVG(fg3m)` và tỷ lệ thử sức ném 3 `SUM(fg3a) * 100.0 / SUM(fga)`.
* **Minh họa truy vấn SQL:**
```sql
SELECT 
    s.era_name,
    COUNT(DISTINCT f.game_id) AS total_games,
    ROUND(AVG(f.fg3m), 2) AS avg_fg3_made,
    ROUND(AVG(f.fg3a), 2) AS avg_fg3_attempted,
    CAST(SUM(f.fg3m) * 100.0 / NULLIF(SUM(f.fg3a), 0) AS DECIMAL(5,2)) AS fg3_accuracy_pct
FROM dbo.fact_team_game f
JOIN dbo.dim_season s ON f.season_id = s.season_id
GROUP BY s.era_name
ORDER BY avg_fg3_made DESC;
```

---

### 1.3.6. Thống kê điểm số trung bình trong khu vực cận rổ (Points in the Paint) của 5 đội bóng Los Angeles Lakers, Golden State Warriors, Boston Celtics, Miami Heat, Denver Nuggets trong năm 2023.
* **Mục tiêu nghiệp vụ:** Phân tích sự đối lập về phong cách tấn công cận rổ (đánh trung lộ/thể hình) giữa các đội bóng vô địch gần đây.
* **Thao tác OLAP:** *Slice* 5 đội bóng cụ thể, *Dice* theo năm 2023, tính `AVG(pts_paint)`.
* **Minh họa truy vấn SQL:**
```sql
SELECT 
    t.full_name,
    COUNT(*) AS total_games,
    ROUND(AVG(f.pts_paint), 2) AS avg_paint_points,
    ROUND(AVG(f.pts), 2) AS avg_total_points
FROM dbo.fact_team_game f
JOIN dbo.dim_team t ON f.team_id = t.team_id
JOIN dbo.dim_date d ON f.date_key = d.date_key
WHERE t.full_name IN (
    'Los Angeles Lakers', 'Golden State Warriors', 
    'Boston Celtics', 'Miami Heat', 'Denver Nuggets'
)
  AND d.year_number = 2023
GROUP BY t.full_name
ORDER BY avg_paint_points DESC;
```

---

### 1.3.7. Liệt kê top 3 đội bóng có hiệu suất ném rổ tổng thể (FG%) cao nhất ở từng phân khu (Division) trong mùa giải chính thức 2022-23 cùng với tổng số trận thắng đạt được.
* **Mục tiêu nghiệp vụ:** Tìm ra các đội bóng dứt điểm hiệu quả nhất ở mỗi cụm địa lý và đánh giá mức độ đóng góp của hiệu suất ném vào thành tích chung cuộc.
* **Thao tác OLAP:** *Drill-down* theo `division` $\rightarrow$ `team`, tính `SUM(fgm) * 100.0 / SUM(fga)`, lọc Top 3 mỗi phân khu dùng hàm cửa sổ `DENSE_RANK()`.
* **Minh họa truy vấn SQL:**
```sql
WITH RankedTeams AS (
    SELECT 
        t.division,
        t.full_name,
        SUM(f.is_win) AS total_wins,
        CAST(SUM(f.fgm) * 100.0 / NULLIF(SUM(f.fga), 0) AS DECIMAL(5,2)) AS field_goal_pct,
        DENSE_RANK() OVER (
            PARTITION BY t.division 
            ORDER BY SUM(f.fgm) * 100.0 / NULLIF(SUM(f.fga), 0) DESC
        ) AS rank_in_div
    FROM dbo.fact_team_game f
    JOIN dbo.dim_team t ON f.team_id = t.team_id
    JOIN dbo.dim_season s ON f.season_id = s.season_id
    WHERE s.season_display = '2022-23' 
      AND s.season_type = 'Regular Season'
    GROUP BY t.division, t.full_name
)
SELECT division, full_name, total_wins, field_goal_pct, rank_in_div
FROM RankedTeams
WHERE rank_in_div <= 3
ORDER BY division, rank_in_div;
```

---

### 1.3.8. Thống kê số lần làm mất bóng trung bình (Turnovers) của các đội bóng trong các trận thắng so với các trận thua theo từng mùa giải từ năm 2018 đến 2023.
* **Mục tiêu nghiệp vụ:** Định lượng mức độ tác động tiêu cực của sai lầm mất bóng đối với kết quả trận đấu (chỉ số quyết định để ban huấn luyện điều chỉnh lối chơi).
* **Thao tác OLAP:** *Pivot* / gom nhóm theo `season_display` và `is_win`, tính `AVG(tov)`.
* **Minh họa truy vấn SQL:**
```sql
SELECT 
    s.season_display,
    ROUND(AVG(CASE WHEN f.is_win = 1 THEN f.tov END), 2) AS avg_tov_in_wins,
    ROUND(AVG(CASE WHEN f.is_win = 0 THEN f.tov END), 2) AS avg_tov_in_losses,
    ROUND(AVG(CASE WHEN f.is_win = 0 THEN f.tov END) - AVG(CASE WHEN f.is_win = 1 THEN f.tov END), 2) AS tov_difference
FROM dbo.fact_team_game f
JOIN dbo.dim_season s ON f.season_id = s.season_id
JOIN dbo.dim_date d ON f.date_key = d.date_key
WHERE d.year_number BETWEEN 2018 AND 2023
GROUP BY s.season_display
ORDER BY s.season_display DESC;
```

---

### 1.3.9. Top 10 trận đấu có tổng số điểm ghi được của cả hai đội cao nhất lịch sử giải đấu cùng thông tin nhà thi đấu và ngày diễn ra trận đấu.
* **Mục tiêu nghiệp vụ:** Khai thác các trận cầu "mưa điểm số" kịch tính nhất lịch sử NBA để phục vụ các bài viết thống kê truyền thông và phân tích kỷ lục giải đấu.
* **Thao tác OLAP:** Gom nhóm theo `game_id`, kết nối `dim_date` và `dim_arena`, tính `SUM(pts)`, sắp xếp giảm dần và lấy Top 10.
* **Minh họa truy vấn SQL:**
```sql
SELECT TOP 10 
    f.game_id,
    d.full_date,
    a.arena_name,
    a.city,
    SUM(f.pts) AS total_game_points
FROM dbo.fact_team_game f
JOIN dbo.dim_date d ON f.date_key = d.date_key
JOIN dbo.dim_arena a ON f.arena_key = a.arena_key
GROUP BY f.game_id, d.full_date, a.arena_name, a.city
ORDER BY total_game_points DESC;
```

---

### 1.3.10. Liệt kê số lượng trận thắng đối đầu trực tiếp (Head-to-head) giữa hai đội kình địch Los Angeles Lakers và Boston Celtics trong lịch sử các mùa giải Playoffs.
* **Mục tiêu nghiệp vụ:** Phân tích cặp đấu kình địch truyền kiếp vĩ đại nhất lịch sử NBA (Rivalry Matchup) để phục vụ báo cáo đối đầu chuyên sâu.
* **Thao tác OLAP:** Áp dụng kỹ thuật *Role-Playing Dimension*: Lọc `team_id = 1610612747` (LAL) và `opponent_id = 1610612738` (BOS), cắt lát `season_type = 'Playoffs'`.
* **Minh họa truy vấn SQL:**
```sql
SELECT 
    t.full_name AS team_name,
    opp.full_name AS opponent_name,
    COUNT(*) AS total_playoff_matches,
    SUM(f.is_win) AS team_wins,
    COUNT(*) - SUM(f.is_win) AS opponent_wins
FROM dbo.fact_team_game f
JOIN dbo.dim_team t ON f.team_id = t.team_id
JOIN dbo.dim_team opp ON f.opponent_id = opp.team_id
JOIN dbo.dim_season s ON f.season_id = s.season_id
WHERE t.abbreviation = 'LAL' AND opp.abbreviation = 'BOS'
  AND s.season_type = 'Playoffs'
GROUP BY t.full_name, opp.full_name;
```

---

### 1.3.11. Top 5 nhà thi đấu (Arena) có điểm số trung bình mỗi trận của đội chủ nhà cao nhất trong các mùa giải từ 2015 đến 2023.
* **Mục tiêu nghiệp vụ:** Đánh giá những "thánh địa" sân nhà mang lại nguồn cảm hứng ghi điểm bùng nổ nhất cho các đội bóng.
* **Thao tác OLAP:** Kết nối `dim_arena`, cắt lát `is_home = 1` và khoảng thời gian 2015–2023, tính `AVG(pts)`, lấy Top 5.
* **Minh họa truy vấn SQL:**
```sql
SELECT TOP 5 
    a.arena_name,
    a.city,
    COUNT(*) AS home_games_hosted,
    ROUND(AVG(f.pts), 2) AS avg_home_pts
FROM dbo.fact_team_game f
JOIN dbo.dim_arena a ON f.arena_key = a.arena_key
JOIN dbo.dim_date d ON f.date_key = d.date_key
WHERE f.is_home = 1
  AND d.year_number BETWEEN 2015 AND 2023
GROUP BY a.arena_name, a.city
HAVING COUNT(*) >= 50
ORDER BY avg_home_pts DESC;
```

---

### 1.3.12. Thống kê số lượng trận đấu diễn ra theo từng quý trong năm và so sánh điểm số trung bình giữa các trận đấu diễn ra vào ngày thường và ngày cuối tuần.
* **Mục tiêu nghiệp vụ:** Phân tích tính chu kỳ thời gian lịch thi đấu và tác động của ngày cuối tuần đến chất lượng chuyên môn trận đấu.
* **Thao tác OLAP:** *Roll-up* theo `year_number`, `quarter_number` và cờ `is_weekend`, tính `COUNT(*)` và `AVG(pts)`.
* **Minh họa truy vấn SQL:**
```sql
SELECT 
    d.year_number,
    d.quarter_number,
    CASE WHEN d.is_weekend = 1 THEN 'Weekend' ELSE 'Weekday' END AS day_type,
    COUNT(DISTINCT f.game_id) AS total_games,
    ROUND(AVG(f.pts), 2) AS avg_pts_per_team
FROM dbo.fact_team_game f
JOIN dbo.dim_date d ON f.date_key = d.date_key
WHERE d.year_number >= 2020
GROUP BY d.year_number, d.quarter_number, d.is_weekend
ORDER BY d.year_number DESC, d.quarter_number, d.is_weekend;
```

---

### 1.3.13. Top 10 đội bóng có số điểm phản công nhanh (Fast Break Points) trung bình cao nhất mùa giải cùng tỷ lệ chiến thắng của các đội bóng đó.
* **Mục tiêu nghiệp vụ:** Đo lường hiệu quả của trường phái bóng rổ tốc độ cao (Pace & Transition offense) đối với khả năng định đoạt trận đấu.
* **Thao tác OLAP:** Cắt lát mùa giải `2022-23`, *Roll-up* tính `AVG(pts_fast_break)` và `Win Rate`, sắp xếp giảm dần lấy Top 10.
* **Minh họa truy vấn SQL:**
```sql
SELECT TOP 10 
    t.full_name,
    ROUND(AVG(f.pts_fast_break), 2) AS avg_fast_break_pts,
    ROUND(AVG(f.pts), 2) AS avg_total_pts,
    CAST(SUM(f.is_win) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS win_rate_pct
FROM dbo.fact_team_game f
JOIN dbo.dim_team t ON f.team_id = t.team_id
JOIN dbo.dim_season s ON f.season_id = s.season_id
WHERE s.season_display = '2022-23'
GROUP BY t.full_name
ORDER BY avg_fast_break_pts DESC;
```

---

### 1.3.14. Phân tích sự hiện diện của cầu thủ quốc tế (Non-USA) trong các trận thắng của các đội bóng qua bảng cầu nối `player_game`.
* **Mục tiêu nghiệp vụ:** Đánh giá xu hướng toàn cầu hóa tại NBA: Đội bóng nào sở hữu nhiều cầu thủ quốc tế ra sân thi đấu nhất và tỷ lệ chiến thắng của các đội đó ra sao?
* **Thao tác OLAP:** Kết nối bảng Fact $\rightarrow$ `player_game` $\rightarrow$ `dim_player` và `dim_team`, lọc `p.country <> 'USA'`, gom nhóm theo đội bóng.
* **Minh họa truy vấn SQL:**
```sql
SELECT TOP 10 
    t.full_name AS team_name,
    COUNT(DISTINCT p.player_id) AS total_international_players,
    COUNT(DISTINCT pg.game_id) AS matches_with_int_players,
    CAST(SUM(f.is_win) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS team_win_rate_pct
FROM dbo.player_game pg
JOIN dbo.dim_player p ON pg.player_id = p.player_id
JOIN dbo.dim_team t ON pg.team_id = t.team_id
JOIN dbo.fact_team_game f ON pg.game_id = f.game_id AND pg.team_id = f.team_id
WHERE p.country IS NOT NULL AND p.country <> 'USA'
GROUP BY t.full_name
ORDER BY total_international_players DESC;
```

---

### 1.3.15. Thống kê tỷ lệ chiến thắng và hiệu số điểm trung bình của các đội bóng khi đối đầu với các đội bóng thuộc liên đoàn khác (Inter-conference Matchups) qua từng năm từ 2018 đến 2023.
* **Mục tiêu nghiệp vụ:** Đưa ra bức tranh tổng thể so sánh thực lực cạnh tranh giữa hai bờ Đông - Tây (miền nào áp đảo miền nào) trong 5 năm trở lại đây.
* **Thao tác OLAP:** Kết nối Role-Playing Dimension `dim_team` (đội chủ thể) và `dim_team` (đối thủ), lọc điều kiện `team.conference != opponent.conference`, gom nhóm theo `year_number` và `team.conference`.
* **Minh họa truy vấn SQL:**
```sql
SELECT 
    d.year_number,
    t.conference AS team_conference,
    COUNT(*) AS total_interconference_games,
    SUM(f.is_win) AS total_wins,
    CAST(SUM(f.is_win) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS win_rate_pct,
    ROUND(AVG(f.plus_minus), 2) AS avg_plus_minus
FROM dbo.fact_team_game f
JOIN dbo.dim_team t ON f.team_id = t.team_id
JOIN dbo.dim_team opp ON f.opponent_id = opp.team_id
JOIN dbo.dim_date d ON f.date_key = d.date_key
WHERE t.conference <> opp.conference
  AND d.year_number BETWEEN 2018 AND 2023
GROUP BY d.year_number, t.conference
ORDER BY d.year_number DESC, t.conference;
```
