-- Tao co so du lieu
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'NBA_DW')
BEGIN
    CREATE DATABASE NBA_DW;
END
GO

USE NBA_DW;
GO

-- Xoa cac bang cu
IF OBJECT_ID('dbo.player_game', 'U') IS NOT NULL DROP TABLE dbo.player_game;
IF OBJECT_ID('dbo.bridge_player_game', 'U') IS NOT NULL DROP TABLE dbo.bridge_player_game;
IF OBJECT_ID('dbo.fact_team_game', 'U') IS NOT NULL DROP TABLE dbo.fact_team_game;
IF OBJECT_ID('dbo.dim_player', 'U') IS NOT NULL DROP TABLE dbo.dim_player;
IF OBJECT_ID('dbo.dim_arena', 'U') IS NOT NULL DROP TABLE dbo.dim_arena;
IF OBJECT_ID('dbo.dim_team', 'U') IS NOT NULL DROP TABLE dbo.dim_team;
IF OBJECT_ID('dbo.dim_season', 'U') IS NOT NULL DROP TABLE dbo.dim_season;
IF OBJECT_ID('dbo.dim_date', 'U') IS NOT NULL DROP TABLE dbo.dim_date;
GO

-- Tao cac bang Dim va Fact
CREATE TABLE dbo.dim_date (
    date_key            INT NOT NULL,
    full_date           DATE NOT NULL,
    year_number         SMALLINT NOT NULL,
    quarter_number      TINYINT NOT NULL,
    month_number        TINYINT NOT NULL,
    month_name          NVARCHAR(15) NOT NULL,
    day_of_week_name    NVARCHAR(15) NOT NULL,
    is_weekend          BIT NOT NULL,
    CONSTRAINT PK_dim_date PRIMARY KEY CLUSTERED (date_key)
);
GO

CREATE TABLE dbo.dim_season (
    season_id           INT NOT NULL,
    season_display      NVARCHAR(15) NOT NULL,
    season_type         NVARCHAR(30) NOT NULL,
    era_name            NVARCHAR(50) NOT NULL,
    CONSTRAINT PK_dim_season PRIMARY KEY CLUSTERED (season_id)
);
GO

CREATE TABLE dbo.dim_team (
    team_id             BIGINT NOT NULL,
    full_name           NVARCHAR(100) NOT NULL,
    abbreviation        NVARCHAR(10) NOT NULL,
    city                NVARCHAR(50) NOT NULL,
    state               NVARCHAR(50) NOT NULL,
    conference          NVARCHAR(30) NOT NULL,
    division            NVARCHAR(30) NOT NULL,
    CONSTRAINT PK_dim_team PRIMARY KEY CLUSTERED (team_id)
);
GO

CREATE TABLE dbo.dim_arena (
    arena_key           INT IDENTITY(1,1) NOT NULL,
    team_id             BIGINT NULL,
    arena_name          NVARCHAR(100) NOT NULL,
    arena_capacity      INT NULL,
    city                NVARCHAR(50) NULL,
    owner               NVARCHAR(100) NULL,
    head_coach          NVARCHAR(100) NULL,
    CONSTRAINT PK_dim_arena PRIMARY KEY CLUSTERED (arena_key)
);
GO

CREATE TABLE dbo.dim_player (
    player_id           INT NOT NULL,
    full_name           NVARCHAR(100) NOT NULL,
    is_active           BIT NOT NULL,
    position            NVARCHAR(30) NULL,
    height              NVARCHAR(10) NULL,
    weight              FLOAT NULL,
    country             NVARCHAR(50) NULL,
    birthdate           DATE NULL,
    draft_round_num     INT NULL,
    draft_overall_pick  INT NULL,
    from_year           SMALLINT NULL,
    to_year             SMALLINT NULL,
    CONSTRAINT PK_dim_player PRIMARY KEY CLUSTERED (player_id)
);
GO

CREATE TABLE dbo.fact_team_game (
    fact_id             BIGINT IDENTITY(1,1) NOT NULL,
    game_id             NVARCHAR(30) NOT NULL,
    date_key            INT NOT NULL,
    season_id           INT NOT NULL,
    team_id             BIGINT NOT NULL,
    opponent_id         BIGINT NOT NULL,
    arena_key           INT NULL,

    is_home             TINYINT NOT NULL,
    is_win              TINYINT NOT NULL,

    pts                 FLOAT NOT NULL,
    pts_opponent        FLOAT NOT NULL,
    plus_minus          INT NOT NULL,

    fgm                 FLOAT NULL,
    fga                 FLOAT NULL,
    fg3m                FLOAT NULL,
    fg3a                FLOAT NULL,

    reb                 FLOAT NULL,
    ast                 FLOAT NULL,
    tov                 FLOAT NULL,

    pts_paint           FLOAT NULL,
    pts_fast_break      FLOAT NULL,

    game_count          TINYINT DEFAULT 1 NOT NULL,

    CONSTRAINT PK_fact_team_game PRIMARY KEY CLUSTERED (fact_id),
    CONSTRAINT FK_fact_date FOREIGN KEY (date_key) REFERENCES dbo.dim_date(date_key),
    CONSTRAINT FK_fact_season FOREIGN KEY (season_id) REFERENCES dbo.dim_season(season_id),
    CONSTRAINT FK_fact_team FOREIGN KEY (team_id) REFERENCES dbo.dim_team(team_id),
    CONSTRAINT FK_fact_opponent FOREIGN KEY (opponent_id) REFERENCES dbo.dim_team(team_id),
    CONSTRAINT FK_fact_arena FOREIGN KEY (arena_key) REFERENCES dbo.dim_arena(arena_key)
);
GO

CREATE TABLE dbo.player_game (
    game_id             NVARCHAR(30) NOT NULL,
    player_id           INT NOT NULL,
    team_id             BIGINT NOT NULL,
    CONSTRAINT PK_player_game PRIMARY KEY CLUSTERED (game_id, player_id),
    CONSTRAINT FK_player_game_player FOREIGN KEY (player_id) REFERENCES dbo.dim_player(player_id),
    CONSTRAINT FK_player_game_team FOREIGN KEY (team_id) REFERENCES dbo.dim_team(team_id)
);
GO

-- Tao chi muc
CREATE NONCLUSTERED INDEX IX_fact_date ON dbo.fact_team_game(date_key);
CREATE NONCLUSTERED INDEX IX_fact_season ON dbo.fact_team_game(season_id);
CREATE NONCLUSTERED INDEX IX_fact_team ON dbo.fact_team_game(team_id);
CREATE NONCLUSTERED INDEX IX_fact_opponent ON dbo.fact_team_game(opponent_id);
CREATE NONCLUSTERED INDEX IX_fact_arena ON dbo.fact_team_game(arena_key);
CREATE NONCLUSTERED INDEX IX_fact_game_id ON dbo.fact_team_game(game_id);

CREATE NONCLUSTERED INDEX IX_player_game_player ON dbo.player_game(player_id);
CREATE NONCLUSTERED INDEX IX_player_game_team ON dbo.player_game(team_id);
GO

PRINT N'TẠO CẤU TRÚC STAR SCHEMA TRONG NBA_DW THÀNH CÔNG!';
GO
