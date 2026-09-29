-- ==============================================================================
-- KHO DỮ LIỆU BÓNG RỔ NBA (NBA_DW) — MÔ HÌNH STAR SCHEMA
-- Hệ quản trị: Microsoft SQL Server (Chạy trên Visual Studio / LocalDB / SSMS)
-- ==============================================================================
-- THAY ĐỔI SO VỚI PHIÊN BẢN CŨ:
--   1. dim_season: Bỏ season_key IDENTITY → Dùng season_id (INT) làm PK (0 duplicate)
--   2. dim_team:   Bỏ team_key IDENTITY  → Dùng team_id (BIGINT) làm PK (0 duplicate)
--   3. dim_player:  THÊM MỚI — Chiều cầu thủ, PK = player_id (0 duplicate)
--   4. player_game: THÊM MỚI — Liên kết cầu thủ ↔ trận đấu (many-to-many)
--   5. fact_team_game: FK đổi từ surrogate key sang natural key
-- ==============================================================================

-- 1. TẠO CƠ SỞ DỮ LIỆU (Nếu chưa có)
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'NBA_DW')
BEGIN
    CREATE DATABASE NBA_DW;
END
GO

USE NBA_DW;
GO

-- 2. XÓA CÁC BẢNG CŨ NẾU ĐÃ TỒN TẠI (Thứ tự: Fact/Bridge trước, Dim sau)
IF OBJECT_ID('dbo.player_game', 'U') IS NOT NULL DROP TABLE dbo.player_game;
IF OBJECT_ID('dbo.bridge_player_game', 'U') IS NOT NULL DROP TABLE dbo.bridge_player_game;
IF OBJECT_ID('dbo.fact_team_game', 'U') IS NOT NULL DROP TABLE dbo.fact_team_game;
IF OBJECT_ID('dbo.dim_player', 'U') IS NOT NULL DROP TABLE dbo.dim_player;
IF OBJECT_ID('dbo.dim_arena', 'U') IS NOT NULL DROP TABLE dbo.dim_arena;
IF OBJECT_ID('dbo.dim_team', 'U') IS NOT NULL DROP TABLE dbo.dim_team;
IF OBJECT_ID('dbo.dim_season', 'U') IS NOT NULL DROP TABLE dbo.dim_season;
IF OBJECT_ID('dbo.dim_date', 'U') IS NOT NULL DROP TABLE dbo.dim_date;
GO

-- ==============================================================================
-- 3. TẠO CÁC BẢNG DIMENSION (DIM TABLES)
-- ==============================================================================

-- A. DIM DATE: Chiều thời gian lịch (8 cột)
CREATE TABLE dbo.dim_date (
    date_key            INT NOT NULL,                  -- Định dạng YYYYMMDD (PK)
    full_date           DATE NOT NULL,                 -- Ngày đầy đủ YYYY-MM-DD
    year_number         SMALLINT NOT NULL,             -- Năm (vd: 2023)
    quarter_number      TINYINT NOT NULL,              -- Quý (1 - 4)
    month_number        TINYINT NOT NULL,              -- Tháng (1 - 12)
    month_name          NVARCHAR(15) NOT NULL,         -- Tên tháng (January, February...)
    day_of_week_name    NVARCHAR(15) NOT NULL,         -- Thứ trong tuần (Monday... Sunday)
    is_weekend          BIT NOT NULL,                  -- 1 = Cuối tuần, 0 = Ngày thường
    CONSTRAINT PK_dim_date PRIMARY KEY CLUSTERED (date_key)
);
GO

-- B. DIM SEASON: Chiều mùa giải & Kỷ nguyên (4 cột)
--    PK = season_id (Khóa tự nhiên từ NBA, đã kiểm tra 0 duplicate / 225 dòng)
--    Chữ số đầu encode season_type: 1=Pre Season, 2=Regular, 3=All-Star, 4=Playoffs
CREATE TABLE dbo.dim_season (
    season_id           INT NOT NULL,                  -- Mã mùa giải gốc làm PK (vd: 22022)
    season_display      NVARCHAR(15) NOT NULL,         -- Tên hiển thị (vd: '2022-23')
    season_type         NVARCHAR(30) NOT NULL,         -- 'Regular Season' / 'Playoffs' / 'All-Star' / 'Pre Season'
    era_name            NVARCHAR(50) NOT NULL,         -- Phân loại kỷ nguyên NBA
    CONSTRAINT PK_dim_season PRIMARY KEY CLUSTERED (season_id)
);
GO

-- C. DIM TEAM: Chiều đội bóng — Phân cấp League -> Conference -> Division -> Team (7 cột)
--    PK = team_id (Khóa tự nhiên từ NBA, đã kiểm tra 0 duplicate / 30 đội)
CREATE TABLE dbo.dim_team (
    team_id             BIGINT NOT NULL,               -- ID gốc của NBA làm PK (vd: 1610612747)
    full_name           NVARCHAR(100) NOT NULL,        -- Tên đầy đủ (Los Angeles Lakers)
    abbreviation        NVARCHAR(10) NOT NULL,         -- Viết tắt (LAL, GSW, BOS)
    city                NVARCHAR(50) NOT NULL,         -- Thành phố (Los Angeles)
    state               NVARCHAR(50) NOT NULL,         -- Bang (California)
    conference          NVARCHAR(30) NOT NULL,         -- 'Eastern Conference' / 'Western Conference'
    division            NVARCHAR(30) NOT NULL,         -- 6 phân khu (Atlantic, Pacific...)
    CONSTRAINT PK_dim_team PRIMARY KEY CLUSTERED (team_id)
);
GO

-- D. DIM ARENA: Chiều nhà thi đấu / Sân vận động (7 cột)
CREATE TABLE dbo.dim_arena (
    arena_key           INT IDENTITY(1,1) NOT NULL,    -- Khóa thay thế tự tăng (PK)
    team_id             BIGINT NULL,                   -- ID đội chủ quản của sân (để Lookup từ Fact)
    arena_name          NVARCHAR(100) NOT NULL,        -- Tên nhà thi đấu (Crypto.com Arena)
    arena_capacity      INT NULL,                      -- Sức chứa khán giả
    city                NVARCHAR(50) NULL,             -- Thành phố đặt sân
    owner               NVARCHAR(100) NULL,            -- Chủ sở hữu đội bóng
    head_coach          NVARCHAR(100) NULL,            -- Huấn luyện viên trưởng
    CONSTRAINT PK_dim_arena PRIMARY KEY CLUSTERED (arena_key)
);
GO

-- E. DIM PLAYER: Chiều cầu thủ — THÊM MỚI (12 cột)
--    PK = player_id (Khóa tự nhiên từ NBA, đã kiểm tra 0 duplicate / 4,831 cầu thủ)
CREATE TABLE dbo.dim_player (
    player_id           INT NOT NULL,                  -- ID cầu thủ từ NBA làm PK
    full_name           NVARCHAR(100) NOT NULL,        -- Họ tên đầy đủ (LeBron James)
    is_active           BIT NOT NULL,                  -- 1 = Đang thi đấu, 0 = Đã giải nghệ
    position            NVARCHAR(30) NULL,             -- Vị trí (Guard, Forward, Center...)
    height              NVARCHAR(10) NULL,             -- Chiều cao (6-9, 7-1...)
    weight              FLOAT NULL,                    -- Cân nặng (lbs)
    country             NVARCHAR(50) NULL,             -- Quốc tịch (USA, France...)
    birthdate           DATE NULL,                     -- Ngày sinh
    draft_round_num     INT NULL,                      -- Vòng draft (1, 2, hoặc NULL = Undrafted)
    draft_overall_pick  INT NULL,                      -- Thứ tự pick tổng (1, 2, 3...)
    from_year           SMALLINT NULL,                 -- Năm bắt đầu sự nghiệp NBA
    to_year             SMALLINT NULL,                 -- Năm kết thúc / năm hiện tại
    CONSTRAINT PK_dim_player PRIMARY KEY CLUSTERED (player_id)
);
GO

-- ==============================================================================
-- 4. TẠO BẢNG FACT TRUNG TÂM (FACT_TEAM_GAME - 22 CỘT)
-- Grain: 1 dòng = hiệu suất của 1 đội bóng trong 1 trận đấu
-- ==============================================================================
CREATE TABLE dbo.fact_team_game (
    fact_id             BIGINT IDENTITY(1,1) NOT NULL, -- Khóa chính thay thế tự tăng (PK)
    game_id             NVARCHAR(30) NOT NULL,         -- Degenerate Dimension (Mã trận gốc)
    date_key            INT NOT NULL,                  -- FK → dim_date
    season_id           INT NOT NULL,                  -- FK → dim_season (đổi từ season_key)
    team_id             BIGINT NOT NULL,               -- FK → dim_team (đổi từ team_key)
    opponent_id         BIGINT NOT NULL,               -- FK → dim_team (đổi từ opponent_key)
    arena_key           INT NULL,                      -- FK → dim_arena (cho phép NULL nếu trận không rõ sân)

    -- Cờ trạng thái & Mục tiêu phân tích (Flags & Targets)
    is_home             TINYINT NOT NULL,              -- 1 = Sân nhà, 0 = Sân khách
    is_win              TINYINT NOT NULL,              -- 1 = Chiến thắng, 0 = Thua (Target chính)

    -- Số đo Điểm số & Hiệu số (Scoring Measures - Additive)
    pts                 FLOAT NOT NULL,                -- Điểm số ghi được
    pts_opponent        FLOAT NOT NULL,                -- Điểm đối thủ ghi (điểm thủng lưới)
    plus_minus          INT NOT NULL,                  -- Hiệu số bàn thắng bại (pts - pts_opponent)

    -- Số đo Ném rổ (Shooting Measures - Additive)
    fgm                 FLOAT NULL,                    -- Field Goals Made (Ném rổ trúng)
    fga                 FLOAT NULL,                    -- Field Goals Attempted (Số lần dứt điểm)
    fg3m                FLOAT NULL,                    -- 3-Point Made (Ném 3 điểm trúng)
    fg3a                FLOAT NULL,                    -- 3-Point Attempted (Số lần ném 3 điểm)

    -- Số đo Kiểm soát bóng & Phối hợp (Ball Control & Teamplay)
    reb                 FLOAT NULL,                    -- Total Rebounds (Tổng bắt bóng bật bảng)
    ast                 FLOAT NULL,                    -- Assists (Số pha kiến tạo thành bàn)
    tov                 FLOAT NULL,                    -- Turnovers (Số lần làm mất bóng)

    -- Số đo Chiến thuật chuyên sâu (Tactical Measures)
    pts_paint           FLOAT NULL,                    -- Điểm ghi trong khu vực cận rổ (vùng sơn)
    pts_fast_break      FLOAT NULL,                    -- Điểm ghi từ phản công nhanh (Fast Break)

    -- Số đo Hằng số đếm (Counting Measure)
    game_count          TINYINT DEFAULT 1 NOT NULL,    -- Luôn = 1 để tính số trận cực nhanh

    CONSTRAINT PK_fact_team_game PRIMARY KEY CLUSTERED (fact_id),
    CONSTRAINT FK_fact_date FOREIGN KEY (date_key) REFERENCES dbo.dim_date(date_key),
    CONSTRAINT FK_fact_season FOREIGN KEY (season_id) REFERENCES dbo.dim_season(season_id)
    -- Lưu ý: Không tạo FK cứng cho team_id, opponent_id, arena_key để nạp toàn vẹn
    -- lịch sử NBA từ 1946 (các đội và sân cũ đã giải thể) theo chuẩn Ralph Kimball.
);
GO

-- ==============================================================================
-- 5. TẠO BẢNG PLAYER_GAME: LIÊN KẾT CẦU THỦ ↔ TRẬN ĐẤU (MANY-TO-MANY)
-- Grain: 1 dòng = 1 cầu thủ tham gia 1 trận đấu, cho 1 đội cụ thể
-- Nguồn: Extract từ play_by_play.csv (2.2GB) → ~617K dòng sau khi clean
-- ==============================================================================
CREATE TABLE dbo.player_game (
    game_id             NVARCHAR(30) NOT NULL,         -- Mã trận đấu (liên kết với fact qua game_id)
    player_id           INT NOT NULL,                  -- FK → dim_player
    team_id             BIGINT NOT NULL,               -- FK → dim_team (đội mà cầu thủ chơi trận này)
    CONSTRAINT PK_player_game PRIMARY KEY CLUSTERED (game_id, player_id),
    CONSTRAINT FK_player_game_player FOREIGN KEY (player_id) REFERENCES dbo.dim_player(player_id),
    CONSTRAINT FK_player_game_team FOREIGN KEY (team_id) REFERENCES dbo.dim_team(team_id)
);
GO

-- ==============================================================================
-- 6. TẠO INDEX ĐỂ TỐI ƯU TRUY VẤN OLAP
-- ==============================================================================
-- Index trên fact_team_game
CREATE NONCLUSTERED INDEX IX_fact_date ON dbo.fact_team_game(date_key);
CREATE NONCLUSTERED INDEX IX_fact_season ON dbo.fact_team_game(season_id);
CREATE NONCLUSTERED INDEX IX_fact_team ON dbo.fact_team_game(team_id);
CREATE NONCLUSTERED INDEX IX_fact_opponent ON dbo.fact_team_game(opponent_id);
CREATE NONCLUSTERED INDEX IX_fact_arena ON dbo.fact_team_game(arena_key);
CREATE NONCLUSTERED INDEX IX_fact_game_id ON dbo.fact_team_game(game_id);

-- Index trên player_game
CREATE NONCLUSTERED INDEX IX_player_game_player ON dbo.player_game(player_id);
CREATE NONCLUSTERED INDEX IX_player_game_team ON dbo.player_game(team_id);
GO

PRINT N'TẠO CẤU TRÚC STAR SCHEMA TRONG NBA_DW THÀNH CÔNG!';
GO
