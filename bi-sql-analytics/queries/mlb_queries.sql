-- MLB Baseball Analysis (IT 340)
-- Dataset: Lahman Baseball Database

-- 3.5 Best pitchers by career ERA (minimum 1,000 innings pitched)
SELECT
    pe.nameFirst || ' ' || pe.nameLast AS PitcherName,
    SUM(p.W) AS CareerWins,
    ROUND(SUM(p.ER) * 27.0 / NULLIF(SUM(p.IPouts), 0), 2) AS CareerERA,
    SUM(p.SO) AS CareerStrikeouts,
    ROUND(SUM(p.IPouts) / 3.0, 1) AS InningsPitched
FROM Pitching p
JOIN People pe
    ON p.playerID = pe.playerID
GROUP BY p.playerID, pe.nameFirst, pe.nameLast
HAVING SUM(p.IPouts) >= 3000
ORDER BY CareerERA ASC
LIMIT 10;


-- 3.5 Top 3 teams by record over the latest 3 seasons
WITH RecentYears AS (
    SELECT DISTINCT yearID
    FROM Teams
    ORDER BY yearID DESC
    LIMIT 3
)
SELECT
    t.name AS TeamName,
    SUM(t.W) AS TotalWins,
    SUM(t.L) AS TotalLosses,
    ROUND(CAST(SUM(t.W) AS FLOAT) / CAST(SUM(t.G) AS FLOAT), 3) AS WinPercentage
FROM Teams t
JOIN RecentYears ry
    ON t.yearID = ry.yearID
GROUP BY t.franchID, t.name
ORDER BY WinPercentage DESC
LIMIT 3;


-- 4.5 Best batters by career OPS (minimum 3,000 at-bats)
WITH clean AS (
    SELECT
        playerid,
        COALESCE(NULLIF(ab, '')::numeric, 0)  AS ab,
        COALESCE(NULLIF(h, '')::numeric, 0)   AS h,
        COALESCE(NULLIF(x2b, '')::numeric, 0) AS x2b,
        COALESCE(NULLIF(x3b, '')::numeric, 0) AS x3b,
        COALESCE(NULLIF(hr, '')::numeric, 0)  AS hr,
        COALESCE(NULLIF(bb, '')::numeric, 0)  AS bb,
        COALESCE(NULLIF(hbp, '')::numeric, 0) AS hbp,
        COALESCE(NULLIF(sf, '')::numeric, 0)  AS sf
    FROM laman.batting
)
SELECT
    pe.namefirst,
    pe.namelast,
    SUM(c.ab) AS Total_At_Bats,
    SUM(c.h)  AS Total_Hits,
    ROUND(SUM(c.h + c.bb + c.hbp) / NULLIF(SUM(c.ab + c.bb + c.hbp + c.sf), 0), 3) AS OBP,
    ROUND(SUM(c.h + c.x2b + 2 * c.x3b + 3 * c.hr) / NULLIF(SUM(c.ab), 0), 3) AS SLG,
    ROUND(
        SUM(c.h + c.bb + c.hbp) / NULLIF(SUM(c.ab + c.bb + c.hbp + c.sf), 0)
        + SUM(c.h + c.x2b + 2 * c.x3b + 3 * c.hr) / NULLIF(SUM(c.ab), 0),
        3
    ) AS Career_OPS
FROM clean c
JOIN laman.people pe ON c.playerid::text = pe.playerid::text
GROUP BY c.playerid, pe.namefirst, pe.namelast
HAVING SUM(c.ab) >= 3000
ORDER BY Career_OPS DESC
LIMIT 10;


-- 5.4 Query 1: Schools producing the most players with 30+ RBI seasons
WITH clean_batting AS (
    SELECT
        playerid,
        yearid,
        COALESCE(NULLIF(rbi, '')::numeric, 0) AS rbi
    FROM laman.batting
),
player_season AS (
    SELECT playerid, yearid, SUM(rbi) AS season_rbi
    FROM clean_batting
    GROUP BY playerid, yearid
),
player_summary AS (
    SELECT
        playerid,
        COUNT(*) FILTER (WHERE season_rbi >= 30) AS seasons_30plus
    FROM player_season
    GROUP BY playerid
),
school_players AS (
    SELECT DISTINCT playerid, schoolid
    FROM laman.collegeplaying
),
school_totals AS (
    SELECT
        sp.schoolid,
        COUNT(*) AS batters_from_school,
        COUNT(*) FILTER (WHERE ps.seasons_30plus > 0) AS players_with_30_rbi,
        COALESCE(SUM(ps.seasons_30plus), 0) AS total_30_rbi_seasons
    FROM school_players sp
    JOIN player_summary ps ON sp.playerid = ps.playerid
    GROUP BY sp.schoolid
)
SELECT
    RANK() OVER (ORDER BY st.players_with_30_rbi DESC) AS school_rank,
    s.c2 AS school,
    st.players_with_30_rbi,
    st.batters_from_school,
    ROUND(100.0 * st.players_with_30_rbi / st.batters_from_school, 1) AS pct_reaching_30_rbi,
    st.total_30_rbi_seasons
FROM school_totals st
JOIN laman.schools s ON st.schoolid = s.c1
ORDER BY school_rank, school
LIMIT 10;


-- 5.4 Query 2: Top run producer (career RBI) at each top school
WITH clean_batting AS (
    SELECT
        playerid,
        yearid,
        COALESCE(NULLIF(rbi, '')::numeric, 0) AS rbi
    FROM laman.batting
),
player_season AS (
    SELECT playerid, yearid, SUM(rbi) AS season_rbi
    FROM clean_batting
    GROUP BY playerid, yearid
),
player_summary AS (
    SELECT
        playerid,
        SUM(season_rbi) AS career_rbi,
        COUNT(*) FILTER (WHERE season_rbi >= 30) AS seasons_30plus
    FROM player_season
    GROUP BY playerid
),
school_players AS (
    SELECT DISTINCT playerid, schoolid
    FROM laman.collegeplaying
),
school_totals AS (
    SELECT
        sp.schoolid,
        COUNT(*) FILTER (WHERE ps.seasons_30plus > 0) AS players_with_30_rbi
    FROM school_players sp
    JOIN player_summary ps ON sp.playerid = ps.playerid
    GROUP BY sp.schoolid
),
top_schools AS (
    SELECT
        schoolid,
        players_with_30_rbi,
        RANK() OVER (ORDER BY players_with_30_rbi DESC) AS school_rank
    FROM school_totals
),
ranked_players AS (
    SELECT
        sp.schoolid,
        sp.playerid,
        ps.career_rbi,
        ROW_NUMBER() OVER (PARTITION BY sp.schoolid ORDER BY ps.career_rbi DESC) AS rn
    FROM school_players sp
    JOIN player_summary ps ON sp.playerid = ps.playerid
)
SELECT
    ts.school_rank,
    s.c2 AS school,
    pe.namefirst,
    pe.namelast,
    rp.career_rbi
FROM top_schools ts
JOIN ranked_players rp ON ts.schoolid = rp.schoolid AND rp.rn = 1
JOIN laman.schools s ON ts.schoolid = s.c1
JOIN laman.people pe ON rp.playerid = pe.playerid
WHERE ts.school_rank <= 10
ORDER BY ts.school_rank, school;
