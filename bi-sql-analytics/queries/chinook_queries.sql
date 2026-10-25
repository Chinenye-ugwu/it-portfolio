-- Chinook Music Analytics (IT 340)
-- Dataset: Chinook digital music store database

-- 3.3 Employees with their manager and their manager's manager
SELECT
    e.FirstName AS EmployeeFirstName,
    e.LastName AS EmployeeLastName,
    m.FirstName AS ManagerFirstName,
    m.LastName AS ManagerLastName,
    gm.FirstName AS ManagerManagerFirstName,
    gm.LastName AS ManagerManagerLastName
FROM Employee e
LEFT JOIN Employee m
    ON e.ReportsTo = m.EmployeeId
LEFT JOIN Employee gm
    ON m.ReportsTo = gm.EmployeeId
ORDER BY gm.LastName, m.LastName, e.LastName;


-- 3.3 Artists with the most songs
SELECT
    ar.Name AS Artist,
    COUNT(t.TrackId) AS NumberOfSongs
FROM Artist ar
JOIN Album al
    ON ar.ArtistId = al.ArtistId
JOIN Track t
    ON al.AlbumId = t.AlbumId
GROUP BY ar.ArtistId, ar.Name
ORDER BY NumberOfSongs DESC
LIMIT 10;


-- 4.3 Artists with the strongest revenue growth trend
-- (early period 2009-2011 vs recent period 2012-2013, minimum 5 tracks sold)
WITH ArtistYearSales AS (
    SELECT
        ar.ArtistId,
        ar.Name AS ArtistName,
        strftime('%Y', i.InvoiceDate) AS SalesYear,
        COUNT(il.InvoiceLineId) AS TracksSold,
        SUM(il.UnitPrice * il.Quantity) AS YearlyRevenue
    FROM Artist ar
    JOIN Album al ON ar.ArtistId = al.ArtistId
    JOIN Track t ON al.AlbumId = t.AlbumId
    JOIN InvoiceLine il ON t.TrackId = il.TrackId
    JOIN Invoice i ON il.InvoiceId = i.InvoiceId
    GROUP BY ar.ArtistId, ar.Name, SalesYear
),
ArtistTrend AS (
    SELECT
        ArtistId,
        ArtistName,
        SUM(TracksSold) AS TotalTracksSold,
        AVG(CASE WHEN SalesYear IN ('2009','2010','2011') THEN YearlyRevenue END) AS EarlyAvgRevenue,
        AVG(CASE WHEN SalesYear IN ('2012','2013') THEN YearlyRevenue END) AS RecentAvgRevenue
    FROM ArtistYearSales
    GROUP BY ArtistId, ArtistName
),
ArtistGrowth AS (
    SELECT
        ArtistId,
        ArtistName,
        TotalTracksSold,
        ROUND(EarlyAvgRevenue, 2) AS EarlyAvgRevenue,
        ROUND(RecentAvgRevenue, 2) AS RecentAvgRevenue,
        ROUND(((RecentAvgRevenue - EarlyAvgRevenue) / EarlyAvgRevenue) * 100, 2) AS RevenueGrowthPercent
    FROM ArtistTrend
    WHERE EarlyAvgRevenue IS NOT NULL
      AND RecentAvgRevenue IS NOT NULL
      AND EarlyAvgRevenue > 0
      AND TotalTracksSold >= 5
)
SELECT
    ArtistName,
    TotalTracksSold,
    EarlyAvgRevenue,
    RecentAvgRevenue,
    RevenueGrowthPercent,
    DENSE_RANK() OVER (ORDER BY RevenueGrowthPercent DESC) AS GrowthRank
FROM ArtistGrowth
ORDER BY RevenueGrowthPercent DESC
LIMIT 10;


-- 5.2 Renumbering tracks for a new multidisc compilation album
-- (six Rock artists, four longest tracks each, new disc every 80 minutes)
WITH selected_tracks AS (
    SELECT
        ar.name AS artist_name,
        t.name AS track_name,
        t.milliseconds::numeric AS ms
    FROM chinook.track t
    JOIN chinook.genre g ON t.genreid::integer = g.genreid::integer
    JOIN chinook.album al ON t.albumid::integer = al.albumid::integer
    JOIN chinook.artist ar ON al.artistid::integer = ar.artistid::integer
    WHERE g.name = 'Rock'
      AND ar.name IN ('Led Zeppelin', 'Deep Purple', 'Pearl Jam',
                      'Van Halen', 'Santana', 'Foo Fighters')
      AND LENGTH(t.name) < 100
      AND t.milliseconds::numeric <= 600000
),
one_version AS (
    SELECT
        artist_name, track_name, ms,
        ROW_NUMBER() OVER (PARTITION BY artist_name, LOWER(track_name)
                           ORDER BY ms DESC) AS version_rank
    FROM selected_tracks
),
top_per_artist AS (
    SELECT
        artist_name, track_name, ms,
        ROW_NUMBER() OVER (PARTITION BY artist_name ORDER BY ms DESC) AS artist_rank
    FROM one_version
    WHERE version_rank = 1
),
album_tracks AS (
    SELECT * FROM top_per_artist WHERE artist_rank <= 4
),
sequenced AS (
    SELECT
        artist_name, track_name, ms,
        ROW_NUMBER() OVER (ORDER BY artist_rank, artist_name) AS overall_track_number,
        SUM(ms) OVER (ORDER BY artist_rank, artist_name
                      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) - ms AS start_ms
    FROM album_tracks
)
SELECT
    FLOOR(start_ms / 4800000)::int + 1 AS disc_number,
    ROW_NUMBER() OVER (PARTITION BY FLOOR(start_ms / 4800000)
                       ORDER BY overall_track_number) AS track_on_disc,
    overall_track_number,
    artist_name,
    track_name,
    ROUND(ms / 60000, 2) AS minutes
FROM sequenced
ORDER BY overall_track_number;
