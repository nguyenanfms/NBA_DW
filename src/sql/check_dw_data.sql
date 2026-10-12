USE NBA_DW;
GO

SELECT 'dim_date' AS ten_bang, COUNT_BIG(*) AS so_dong FROM dbo.dim_date
UNION ALL
SELECT 'dim_season' AS ten_bang, COUNT_BIG(*) AS so_dong FROM dbo.dim_season
UNION ALL
SELECT 'dim_team' AS ten_bang, COUNT_BIG(*) AS so_dong FROM dbo.dim_team
UNION ALL
SELECT 'dim_arena' AS ten_bang, COUNT_BIG(*) AS so_dong FROM dbo.dim_arena
UNION ALL
SELECT 'dim_player' AS ten_bang, COUNT_BIG(*) AS so_dong FROM dbo.dim_player
UNION ALL
SELECT 'player_game' AS ten_bang, COUNT_BIG(*) AS so_dong FROM dbo.player_game
UNION ALL
SELECT 'fact_team_game' AS ten_bang, COUNT_BIG(*) AS so_dong FROM dbo.fact_team_game;
GO

SELECT TOP (10) * FROM dbo.dim_date ORDER BY date_key;
SELECT TOP (10) * FROM dbo.dim_season ORDER BY season_id;
SELECT TOP (10) * FROM dbo.dim_team ORDER BY team_id;
SELECT TOP (10) * FROM dbo.dim_arena ORDER BY arena_key;
SELECT TOP (10) * FROM dbo.dim_player ORDER BY player_id;
SELECT TOP (10) * FROM dbo.player_game ORDER BY game_id, player_id;
SELECT TOP (10) * FROM dbo.fact_team_game ORDER BY fact_id;
GO

SELECT game_id, team_id, COUNT(*) AS so_dong
FROM dbo.fact_team_game
GROUP BY game_id, team_id HAVING COUNT(*) > 1;

SELECT game_id, player_id, COUNT(*) AS so_dong
FROM dbo.player_game
GROUP BY game_id, player_id HAVING COUNT(*) > 1;

SELECT game_id, COUNT(*) AS so_dong
FROM dbo.fact_team_game GROUP BY game_id
HAVING COUNT(*) <> 2
 OR SUM(CASE WHEN is_home = 1 THEN 1 ELSE 0 END) <> 1
 OR SUM(CASE WHEN is_home = 0 THEN 1 ELSE 0 END) <> 1;
GO

SELECT 'fact_date' AS quan_he, COUNT_BIG(*) AS so_dong_mo_coi
FROM dbo.fact_team_game AS f LEFT JOIN dbo.dim_date AS d
 ON f.date_key = d.date_key
WHERE f.date_key IS NOT NULL AND d.date_key IS NULL
UNION ALL
SELECT 'fact_season' AS quan_he, COUNT_BIG(*) AS so_dong_mo_coi
FROM dbo.fact_team_game AS f LEFT JOIN dbo.dim_season AS d
 ON f.season_id = d.season_id
WHERE f.season_id IS NOT NULL AND d.season_id IS NULL
UNION ALL
SELECT 'fact_team' AS quan_he, COUNT_BIG(*) AS so_dong_mo_coi
FROM dbo.fact_team_game AS f LEFT JOIN dbo.dim_team AS d
 ON f.team_id = d.team_id
WHERE f.team_id IS NOT NULL AND d.team_id IS NULL
UNION ALL
SELECT 'fact_opponent' AS quan_he, COUNT_BIG(*) AS so_dong_mo_coi
FROM dbo.fact_team_game AS f LEFT JOIN dbo.dim_team AS d
 ON f.opponent_id = d.team_id
WHERE f.opponent_id IS NOT NULL AND d.team_id IS NULL
UNION ALL
SELECT 'fact_arena' AS quan_he, COUNT_BIG(*) AS so_dong_mo_coi
FROM dbo.fact_team_game AS f LEFT JOIN dbo.dim_arena AS d
 ON f.arena_key = d.arena_key
WHERE f.arena_key IS NOT NULL AND d.arena_key IS NULL
UNION ALL
SELECT 'player_game_player' AS quan_he, COUNT_BIG(*) AS so_dong_mo_coi
FROM dbo.player_game AS f LEFT JOIN dbo.dim_player AS d
 ON f.player_id = d.player_id
WHERE f.player_id IS NOT NULL AND d.player_id IS NULL
UNION ALL
SELECT 'player_game_team' AS quan_he, COUNT_BIG(*) AS so_dong_mo_coi
FROM dbo.player_game AS f LEFT JOIN dbo.dim_team AS d
 ON f.team_id = d.team_id
WHERE f.team_id IS NOT NULL AND d.team_id IS NULL;
GO

SELECT COUNT_BIG(*) AS so_dong_thieu_san
FROM dbo.fact_team_game WHERE arena_key IS NULL;

SELECT COUNT_BIG(*) AS so_dong_sai_hieu_so
FROM dbo.fact_team_game
WHERE ABS(plus_minus - (pts - pts_opponent)) > 0.001;

SELECT COUNT_BIG(*) AS so_dong_sai_co
FROM dbo.fact_team_game
WHERE is_home NOT IN (0, 1) OR is_win NOT IN (0, 1)
 OR game_count <> 1;

SELECT COUNT_BIG(*) AS lien_ket_khong_co_trong_fact
FROM dbo.player_game AS p
WHERE NOT EXISTS (SELECT 1 FROM dbo.fact_team_game AS f
 WHERE f.game_id = p.game_id AND f.team_id = p.team_id);
GO
