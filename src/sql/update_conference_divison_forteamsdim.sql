USE NBA_DW;
GO

-- ==============================================================================
-- 1. CẬP NHẬT DIVISION & CONFERENCE CHO 30 FRANCHISE TRONG DIM_TEAM
-- ==============================================================================
-- Atlantic
UPDATE dbo.dim_team SET conference = N'Eastern Conference', division = N'Atlantic'
WHERE team_id IN (1610612738, 1610612751, 1610612752, 1610612755, 1610612761);

-- Central
UPDATE dbo.dim_team SET conference = N'Eastern Conference', division = N'Central'
WHERE team_id IN (1610612741, 1610612739, 1610612765, 1610612754, 1610612749);

-- Southeast
UPDATE dbo.dim_team SET conference = N'Eastern Conference', division = N'Southeast'
WHERE team_id IN (1610612737, 1610612766, 1610612748, 1610612753, 1610612764);

-- Northwest
UPDATE dbo.dim_team SET conference = N'Western Conference', division = N'Northwest'
WHERE team_id IN (1610612743, 1610612750, 1610612760, 1610612757, 1610612762);

-- Pacific
UPDATE dbo.dim_team SET conference = N'Western Conference', division = N'Pacific'
WHERE team_id IN (1610612744, 1610612746, 1610612747, 1610612756, 1610612758);

-- Southwest
UPDATE dbo.dim_team SET conference = N'Western Conference', division = N'Southwest'
WHERE team_id IN (1610612742, 1610612745, 1610612763, 1610612740, 1610612759);
GO

-- ==============================================================================
-- 2. CẬP NHẬT TÊN HIỂN THỊ MÙA GIẢI ĐỊNH DẠNG 'YYYY-YY' TRONG DIM_SEASON
-- ==============================================================================
UPDATE dbo.dim_season 
SET season_display = SUBSTRING(CAST(season_id AS VARCHAR(10)), 2, 4) + '-' + 
                     RIGHT(CAST(CAST(SUBSTRING(CAST(season_id AS VARCHAR(10)), 2, 4) AS INT) + 1 AS VARCHAR(10)), 2)
WHERE LEN(CAST(season_id AS VARCHAR(10))) = 5;
GO

PRINT N'CẬP NHẬT CONFERENCE, DIVISION VÀ SEASON_DISPLAY THÀNH CÔNG!';
GO