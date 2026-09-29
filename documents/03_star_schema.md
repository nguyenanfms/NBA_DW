# THIẾT KẾ MÔ HÌNH STAR SCHEMA — NBA DATA WAREHOUSE

## Tổng quan

- **Chủ đề phân tích:** Giám sát & đánh giá hiệu suất thi đấu các đội bóng NBA qua các mùa giải và theo dõi sự hiện diện của cầu thủ trong từng trận đấu.
- **Phương pháp luận:** Ralph Kimball — Dimensional Modeling (Star Schema kết hợp Bridge Table).
- **Hạt dữ liệu (Grain):** 
  - Bảng Fact `fact_team_game`: Mỗi dòng = hiệu suất thi đấu của **1 đội bóng** trong **1 trận đấu**.
  - Bảng Bridge `player_game`: Mỗi dòng = **1 cầu thủ** tham gia thi đấu cho **1 đội bóng** trong **1 trận đấu**.
- **Nguồn dữ liệu đã tiền xử lý (`dataset/processed/`):**
  - `games_merged.csv` (65,642 trận)
  - `teams_merged.csv` (30 đội)
  - `players_merged.csv` (4,831 cầu thủ)
  - `player_game.csv` (617,110 liên kết cầu thủ ↔ trận đấu)

> [!IMPORTANT]
> Một trận đấu giữa 2 đội sẽ được **unpivot** thành **2 dòng** trong bảng Fact `fact_team_game` (1 dòng cho Đội Nhà, 1 dòng cho Đội Khách), tổng cộng khoảng **~131,284 bản ghi Fact**.
> Khóa chính của `dim_season` (`season_id`) và `dim_team` (`team_id`), `dim_player` (`player_id`) sử dụng **Natural Key** trực tiếp từ nguồn do dữ liệu đã được kiểm tra 100% không trùng lặp (0 duplicate), không null và có tính ổn định cao.

---

## Sơ đồ Star Schema (ERD)

```mermaid
erDiagram
    dim_date ||--o{ fact_team_game : "date_key"
    dim_season ||--o{ fact_team_game : "season_id"
    dim_team ||--o{ fact_team_game : "team_id"
    dim_team ||--o{ fact_team_game : "opponent_id"
    dim_arena ||--o{ fact_team_game : "arena_key"

    fact_team_game ||--o{ player_game : "game_id"
    dim_team ||--o{ player_game : "team_id"
    dim_player ||--o{ player_game : "player_id"

    fact_team_game {
        BIGINT fact_id PK "Khóa chính thay thế tự tăng"
        VARCHAR game_id "Khóa thoái hóa (Degenerate Dim)"
        INT date_key FK "FK → dim_date(date_key)"
        INT season_id FK "FK → dim_season(season_id)"
        BIGINT team_id FK "FK → dim_team(team_id)"
        BIGINT opponent_id FK "FK → dim_team(team_id) (Role-Playing)"
        INT arena_key FK "FK → dim_arena(arena_key)"
        SMALLINT is_home "1 = Sân nhà, 0 = Sân khách"
        SMALLINT is_win "1 = Thắng, 0 = Thua (Target)"
        REAL pts "Điểm ghi được"
        REAL pts_opponent "Điểm đối thủ ghi"
        INT plus_minus "Hiệu số điểm"
        REAL fgm "Field Goals Made"
        REAL fga "Field Goals Attempted"
        REAL fg3m "3-Point Made"
        REAL fg3a "3-Point Attempted"
        REAL reb "Total Rebounds"
        REAL ast "Assists"
        REAL tov "Turnovers"
        INT pts_paint "Points in Paint"
        INT pts_fast_break "Fast Break Points"
        SMALLINT game_count "Hằng số = 1"
    }

    player_game {
        VARCHAR game_id PK,FK "Mã trận đấu (FK → fact_team_game)"
        INT player_id PK,FK "Mã cầu thủ (FK → dim_player)"
        BIGINT team_id FK "Mã đội bóng (FK → dim_team)"
    }

    dim_player {
        INT player_id PK "Mã cầu thủ (Natural Key)"
        VARCHAR full_name "Tên đầy đủ"
        BOOLEAN is_active "Đang thi đấu?"
        VARCHAR position "Vị trí thi đấu"
        VARCHAR height "Chiều cao"
        REAL weight "Cân nặng (lbs)"
        VARCHAR country "Quốc tịch"
        DATE birthdate "Ngày sinh"
        INT draft_round_num "Vòng tuyển chọn (Draft Round)"
        INT draft_overall_pick "Thứ tự pick tổng"
        SMALLINT from_year "Năm bắt đầu"
        SMALLINT to_year "Năm kết thúc"
    }

    dim_date {
        INT date_key PK "YYYYMMDD"
        DATE full_date "Ngày đầy đủ"
        SMALLINT year_number "Năm"
        SMALLINT quarter_number "Quý 1-4"
        SMALLINT month_number "Tháng 1-12"
        VARCHAR month_name "January..."
        VARCHAR day_of_week_name "Monday..."
        BOOLEAN is_weekend "Cuối tuần?"
    }

    dim_season {
        INT season_id PK "Mã mùa giải NBA (Natural Key)"
        VARCHAR season_display "VD: 2022-23"
        VARCHAR season_type "Regular / Playoffs / All-Star"
        VARCHAR era_name "Kỷ nguyên NBA"
    }

    dim_team {
        BIGINT team_id PK "Mã đội bóng NBA (Natural Key)"
        VARCHAR full_name "Tên đầy đủ"
        VARCHAR abbreviation "LAL, GSW, BOS..."
        VARCHAR city "Thành phố"
        VARCHAR state "Bang"
        VARCHAR conference "Eastern / Western"
        VARCHAR division "6 phân khu"
    }

    dim_arena {
        INT arena_key PK "Khóa thay thế tự tăng"
        VARCHAR arena_name "Tên nhà thi đấu"
        INT arena_capacity "Sức chứa"
        VARCHAR city "Thành phố"
        VARCHAR owner "Chủ sở hữu"
        VARCHAR head_coach "Huấn luyện viên trưởng"
    }
```

---

## Cây phân cấp đa chiều (Drill-Down Hierarchies)

```mermaid
flowchart LR
    subgraph H1["Phân cấp Giải đấu (League Hierarchy)"]
        direction LR
        L1["NBA League"] --> L2["Conference\n(Eastern / Western)"]
        L2 --> L3["Division\n(6 phân khu)"]
        L3 --> L4["Team\n(30 đội bóng)"]
    end

    subgraph H2["Phân cấp Thời gian Lịch (Calendar Hierarchy)"]
        direction LR
        T1["Year"] --> T2["Quarter"]
        T2 --> T3["Month"]
        T3 --> T4["Date"]
    end

    subgraph H3["Phân cấp Mùa giải (Season Hierarchy)"]
        direction LR
        S1["Era\n(Kỷ nguyên NBA)"] --> S2["Season Year\n(2022-23)"]
        S2 --> S3["Season Type\n(Regular / Playoffs)"]
    end

    subgraph H4["Phân cấp Cầu thủ (Player Hierarchy)"]
        direction LR
        P1["Country\n(Quốc gia)"] --> P2["Position\n(Guard / Forward / Center)"]
        P2 --> P3["Player\n(Cầu thủ)"]
    end
```

---

## Ánh xạ dữ liệu nguồn (Source-to-Target Mapping)

### 1. Bảng Fact `fact_team_game` ← `games_merged.csv`

| Cột nguồn (CSV) | Cột đích (Fact) | Ghi chú |
|---|---|---|
| `game_id` | `game_id` | Degenerate Dimension |
| `game_date` | → Tra cứu `date_key` | Chuyển đổi thành định dạng `YYYYMMDD` |
| `season_id` | `season_id` | Foreign Key trỏ trực tiếp `dim_season(season_id)` |
| `team_id_home` / `team_id_away` | `team_id` | Unpivot 2 dòng, FK → `dim_team(team_id)` |
| Đội đối diện | `opponent_id` | Role-Playing FK trỏ sang `dim_team(team_id)` |
| Đội nhà | → Tra cứu `arena_key` | Tra cứu theo sân nhà |
| `wl_home` / `wl_away` | `is_win` | W=1, L=0 |
| Vị thế thi đấu | `is_home` | 1 cho Home row, 0 cho Away row |
| `pts_home` / `pts_away` | `pts` | Điểm số ghi được |
| `plus_minus_home` / `_away` | `plus_minus` | Hiệu số điểm |
| `fgm_home` / `fga_home` | `fgm`, `fga` | Ném rổ trúng / lần thử sức |
| `fg3m_home` / `fg3a_home` | `fg3m`, `fg3a` | Ném 3 điểm trúng / lần thử sức |
| `reb_home`, `ast_home`, `tov_home` | `reb`, `ast`, `tov` | Rebounds, Assists, Turnovers |
| `pts_paint_home`, `pts_fb_home` | `pts_paint`, `pts_fast_break` | Điểm vùng sơn, điểm phản công nhanh |
| Hằng số | `game_count` | Luôn bằng 1 |

### 2. Bảng Bridge `player_game` ← `player_game.csv`

| Cột nguồn (CSV) | Cột đích | Ghi chú |
|---|---|---|
| `game_id` | `game_id` | Khóa chính phức hợp & FK liên kết với `fact_team_game` |
| `player_id` | `player_id` | Khóa chính phức hợp & FK trỏ sang `dim_player` |
| `team_id` | `team_id` | FK trỏ sang `dim_team` (đội mà cầu thủ khoác áo trong trận này) |

### 3. Bảng `dim_player` ← `players_merged.csv`

| Cột nguồn (CSV) | Cột đích | Ghi chú |
|---|---|---|
| `player_id` | `player_id` | Primary Key (Natural Key, 4,831 cầu thủ duy nhất) |
| `full_name` | `full_name` | Họ tên đầy đủ |
| `is_active` | `is_active` | 1 = Đang thi đấu, 0 = Giải nghệ |
| `position` | `position` | Guard, Forward, Center... |
| `height`, `weight` | `height`, `weight` | Chiều cao, cân nặng |
| `country`, `birthdate` | `country`, `birthdate` | Quốc gia, ngày sinh |
| `draft_round_num` | `draft_round_num` | Vòng tuyển chọn tân binh |
| `draft_overall_pick` | `draft_overall_pick` | Lượt chọn tổng thể |
| `from_year`, `to_year` | `from_year`, `to_year` | Năm bắt đầu, năm kết thúc |

### 4. Bảng `dim_team` ← `teams_merged.csv`

| Cột nguồn | Cột đích | Ghi chú |
|---|---|---|
| `team_id` | `team_id` | Primary Key (Natural Key, 30 đội duy nhất) |
| `full_name` | `full_name` | Tên đầy đủ chính thức |
| `abbreviation` | `abbreviation` | Tên viết tắt (LAL, GSW, BOS...) |
| `city`, `state` | `city`, `state` | Thành phố, Bang |
| `conference` | `conference` | Eastern Conference / Western Conference |
| `division` | `division` | 6 phân khu địa lý |

### 5. Bảng `dim_season` ← `games_merged.csv`

| Cột nguồn | Cột đích | Ghi chú |
|---|---|---|
| `season_id` | `season_id` | Primary Key (Natural Key, 225 giá trị duy nhất) |
| Chuỗi hiển thị | `season_display` | Ví dụ: '2022-23' |
| `season_type` | `season_type` | Regular Season / Playoffs / All-Star / Pre Season |
| Phân loại năm | `era_name` | 4 Kỷ nguyên lịch sử NBA |

### 6. Bảng `dim_date` ← Sinh tự động từ dải ngày của `game_date`

### 7. Bảng `dim_arena` ← `teams_merged.csv` (Surrogate Key: `arena_key IDENTITY`)
