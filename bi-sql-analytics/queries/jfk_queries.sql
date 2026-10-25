-- JFK Airport Analysis (IT 340)
-- Dataset: JFK flights, weather, planes and airlines

-- 3.4 Most used plane model at JFK
SELECT
    plane.model,
    COUNT(flights.tailnum) AS plane_usage
FROM postgres.nycflights13.flights AS flights
JOIN postgres.nycflights13.planes AS plane
    ON flights.tailnum = plane.tailnum
WHERE flights.origin = 'JFK'
GROUP BY plane.model
ORDER BY plane_usage DESC
LIMIT 1;


-- 4.4 Percentage of windy departures (wind speed > 20 mph) by carrier
WITH flight_times AS (
    SELECT
        f.*,
        (f.dep_time / 100) AS dep_hour,
        make_timestamp(
            f.year, f.month, f.day,
            (f.dep_time / 100), (f.dep_time % 100), 0
        ) AS dep_timestamp
    FROM jfk.flights f
    WHERE f.dep_time IS NOT NULL
      AND f.dep_time BETWEEN 0 AND 2359
),
flight_weather AS (
    SELECT
        ft.carrier, ft.flight, ft.dep_timestamp, w.wind_speed
    FROM flight_times ft
    JOIN jfk.weather w
      ON w.origin = ft.origin
     AND w.year   = ft.year
     AND w.month  = ft.month
     AND w.day    = ft.day
     AND w.hour   = ft.dep_hour
),
carrier_windy AS (
    SELECT
        carrier,
        COUNT(*) AS total_flights,
        COUNT(*) FILTER (WHERE wind_speed > 20) AS windy_flights
    FROM flight_weather
    GROUP BY carrier
)
SELECT
    a.c2 AS carrier_name,
    cw.carrier,
    cw.total_flights,
    cw.windy_flights,
    ROUND(100.0 * cw.windy_flights / cw.total_flights, 2) AS pct_windy_departures
FROM carrier_windy cw
JOIN jfk.airlines a ON a.c1 = cw.carrier
ORDER BY pct_windy_departures DESC;


-- 5.3 Rain vs departure delays
WITH flight_weather_delay AS (
    SELECT
        f.carrier,
        f.dep_delay,
        CASE WHEN w.precip > 0 THEN 'Raining' ELSE 'Clear' END AS rain_condition
    FROM jfk.flights f
    JOIN jfk.weather w
      ON w.origin = f.origin
     AND w.year = f.year
     AND w.month = f.month
     AND w.day = f.day
     AND CAST(w.hour AS INTEGER) = CAST(f.hour AS INTEGER)
    WHERE f.dep_delay IS NOT NULL
      AND w.precip IS NOT NULL
)
SELECT
    rain_condition,
    COUNT(*) AS total_flights,
    ROUND(CAST(AVG(dep_delay) AS NUMERIC), 2) AS avg_departure_delay_mins,
    ROUND(CAST(100.0 * SUM(CASE WHEN dep_delay > 15 THEN 1 ELSE 0 END) / COUNT(*) AS NUMERIC), 2) AS pct_delayed_over_15min
FROM flight_weather_delay
GROUP BY rain_condition;
