CREATE TABLE dim_date (
    date_key INT PRIMARY KEY,
    full_date DATE NOT NULL,
    year_number SMALLINT NOT NULL,
    quarter_number TINYINT NOT NULL,
    month_number TINYINT NOT NULL,
    month_name VARCHAR(15) NOT NULL,
    day_of_week_name VARCHAR(15) NOT NULL,
    is_weekend BIT NOT NULL
);

CREATE TABLE dim_season (
    season_id INT PRIMARY KEY,
    season_display VARCHAR(15) NOT NULL,
    season_type VARCHAR(30) NOT NULL,
    era_name VARCHAR(50) NOT NULL
);

CREATE TABLE dim_team (
    team_id BIGINT PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    abbreviation VARCHAR(10) NOT NULL,
    city VARCHAR(50) NOT NULL,
    state VARCHAR(50) NOT NULL,
    conference VARCHAR(30) NOT NULL,
    division VARCHAR(30) NOT NULL
);

CREATE TABLE dim_arena (
    arena_key INT PRIMARY KEY,
    team_id BIGINT,
    arena_name VARCHAR(100) NOT NULL,
    arena_capacity INT,
    city VARCHAR(50),
    owner VARCHAR(100),
    head_coach VARCHAR(100)
);

CREATE TABLE dim_player (
    player_id INT PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    is_active BIT NOT NULL,
    position VARCHAR(30),
    height VARCHAR(10),
    weight FLOAT,
    country VARCHAR(50),
    birthdate DATE,
    draft_round_num INT,
    draft_overall_pick INT,
    from_year SMALLINT,
    to_year SMALLINT
);

CREATE TABLE fact_team_game (
    fact_id BIGINT PRIMARY KEY,
    game_id VARCHAR(30) NOT NULL,
    date_key INT NOT NULL,
    season_id INT NOT NULL,
    team_id BIGINT NOT NULL,
    opponent_id BIGINT NOT NULL,
    arena_key INT,
    is_home TINYINT NOT NULL,
    is_win TINYINT NOT NULL,
    pts FLOAT NOT NULL,
    pts_opponent FLOAT NOT NULL,
    plus_minus INT NOT NULL,
    fgm FLOAT,
    fga FLOAT,
    fg3m FLOAT,
    fg3a FLOAT,
    reb FLOAT,
    ast FLOAT,
    tov FLOAT,
    pts_paint FLOAT,
    pts_fast_break FLOAT,
    game_count TINYINT NOT NULL,
    FOREIGN KEY (date_key) REFERENCES dim_date(date_key),
    FOREIGN KEY (season_id) REFERENCES dim_season(season_id),
    FOREIGN KEY (team_id) REFERENCES dim_team(team_id),
    FOREIGN KEY (opponent_id) REFERENCES dim_team(team_id),
    FOREIGN KEY (arena_key) REFERENCES dim_arena(arena_key)
);

CREATE TABLE player_game (
    game_id VARCHAR(30) NOT NULL,
    player_id INT NOT NULL,
    team_id BIGINT NOT NULL,
    PRIMARY KEY (game_id, player_id),
    FOREIGN KEY (player_id) REFERENCES dim_player(player_id),
    FOREIGN KEY (team_id) REFERENCES dim_team(team_id)
);
