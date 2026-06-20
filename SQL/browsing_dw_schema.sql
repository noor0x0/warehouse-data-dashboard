-- ============================================================
--  Schema: Star Schema
-- ============================================================

CREATE DATABASE IF NOT EXISTS browsing_dw
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE browsing_dw;

-- ──────────────────────────────────────────────────────────────
-- DIMENSION: DIM_USER
-- ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS dim_user (
  user_id   INT          NOT NULL AUTO_INCREMENT,
  user_name VARCHAR(100) NOT NULL,
  PRIMARY KEY (user_id),
  UNIQUE KEY uq_user_name (user_name)
) ENGINE=InnoDB;

-- ──────────────────────────────────────────────────────────────
-- DIMENSION: DIM_WEBSITE
-- ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS dim_website (
  website_id   INT          NOT NULL AUTO_INCREMENT,
  website_name VARCHAR(150) NOT NULL,
  website_url  VARCHAR(300),
  category     VARCHAR(100),
  PRIMARY KEY (website_id),
  UNIQUE KEY uq_website_name (website_name)
) ENGINE=InnoDB;

-- ──────────────────────────────────────────────────────────────
-- DIMENSION: DIM_DATE
-- ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS dim_date (
  date_id      INT         NOT NULL AUTO_INCREMENT,
  visit_date   DATE        NOT NULL,
  day_of_week  VARCHAR(15) NOT NULL,
  month        VARCHAR(15) NOT NULL,
  month_num    TINYINT     NOT NULL,
  quarter      TINYINT     NOT NULL,
  week_of_year TINYINT     NOT NULL,
  PRIMARY KEY (date_id),
  UNIQUE KEY uq_visit_date (visit_date)
) ENGINE=InnoDB;

-- ──────────────────────────────────────────────────────────────
-- FACT TABLE: FACT_VISITS
-- ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS fact_visits (
  visit_id      INT          NOT NULL AUTO_INCREMENT,
  user_id       INT          NOT NULL,
  website_id    INT          NOT NULL,
  date_id       INT          NOT NULL,
  hour_of_day   TINYINT      NOT NULL COMMENT '0–23',
  time_of_day   VARCHAR(20)  NOT NULL COMMENT 'Morning / Afternoon / Evening / Night',
  visit_datetime DATETIME    NOT NULL,
  PRIMARY KEY (visit_id),
  KEY fk_user    (user_id),
  KEY fk_website (website_id),
  KEY fk_date    (date_id),
  CONSTRAINT fk_user    FOREIGN KEY (user_id)    REFERENCES dim_user    (user_id),
  CONSTRAINT fk_website FOREIGN KEY (website_id) REFERENCES dim_website (website_id),
  CONSTRAINT fk_date    FOREIGN KEY (date_id)    REFERENCES dim_date    (date_id)
) ENGINE=InnoDB;


-- ============================================================
--  ANALYTICAL QUERIES
-- ============================================================

-- ── Q1: Most visited websites overall ──────────────────────
SELECT
  w.website_name,
  w.category,
  COUNT(*) AS total_visits
FROM fact_visits  f
JOIN dim_website  w ON f.website_id = w.website_id
GROUP BY w.website_id, w.website_name, w.category
ORDER BY total_visits DESC
LIMIT 10;

-- ── Q2: Number of visits per user ──────────────────────────
SELECT
  u.user_name,
  COUNT(*) AS total_visits
FROM fact_visits f
JOIN dim_user    u ON f.user_id = u.user_id
GROUP BY u.user_id, u.user_name
ORDER BY total_visits DESC;

-- ── Q3: Most active browsing time (hour) ──────────────────
SELECT
  f.hour_of_day,
  f.time_of_day,
  COUNT(*) AS visit_count
FROM fact_visits f
GROUP BY f.hour_of_day, f.time_of_day
ORDER BY visit_count DESC
LIMIT 10;

-- ── Q4: Visits per day (recent 30 days) ───────────────────
SELECT
  d.visit_date,
  d.day_of_week,
  COUNT(*) AS visits
FROM fact_visits f
JOIN dim_date    d ON f.date_id = d.date_id
GROUP BY d.date_id, d.visit_date, d.day_of_week
ORDER BY d.visit_date DESC
LIMIT 30;

-- ── Q5: Top 10 visited websites ───────────────────────────
SELECT
  w.website_name,
  w.website_url,
  w.category,
  COUNT(*) AS total_visits,
  ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM fact_visits), 2) AS pct
FROM fact_visits  f
JOIN dim_website  w ON f.website_id = w.website_id
GROUP BY w.website_id, w.website_name, w.website_url, w.category
ORDER BY total_visits DESC
LIMIT 10;

-- ── Q6: Visits per user per website ───────────────────────
SELECT
  u.user_name,
  w.website_name,
  COUNT(*) AS visits
FROM fact_visits  f
JOIN dim_user     u ON f.user_id    = u.user_id
JOIN dim_website  w ON f.website_id = w.website_id
GROUP BY u.user_id, u.user_name, w.website_id, w.website_name
ORDER BY u.user_name, visits DESC;

-- ── Q7: Monthly visit trend ────────────────────────────────
SELECT
  d.month,
  d.month_num,
  COUNT(*) AS visits
FROM fact_visits f
JOIN dim_date    d ON f.date_id = d.date_id
GROUP BY d.month, d.month_num
ORDER BY d.month_num;

-- ── Q8: Browsing by time of day per user ──────────────────
SELECT
  u.user_name,
  f.time_of_day,
  COUNT(*) AS visits
FROM fact_visits f
JOIN dim_user    u ON f.user_id = u.user_id
GROUP BY u.user_id, u.user_name, f.time_of_day
ORDER BY u.user_name, visits DESC;

-- ── Q9: Website category popularity ──────────────────────
SELECT
  w.category,
  COUNT(*) AS visits,
  ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM fact_visits), 2) AS pct
FROM fact_visits  f
JOIN dim_website  w ON f.website_id = w.website_id
GROUP BY w.category
ORDER BY visits DESC;

-- ── Q10: Peak browsing day of week ───────────────────────
SELECT
  d.day_of_week,
  COUNT(*) AS visits
FROM fact_visits f
JOIN dim_date    d ON f.date_id = d.date_id
GROUP BY d.day_of_week
ORDER BY visits DESC;

-- ── Q11: Most active user per website ────────────────────
SELECT
  w.website_name,
  u.user_name,
  COUNT(*) AS visits
FROM fact_visits f
JOIN dim_user u ON f.user_id = u.user_id
JOIN dim_website w ON f.website_id = w.website_id
GROUP BY w.website_id, w.website_name, u.user_id, u.user_name
HAVING COUNT(*) = (
  SELECT MAX(t.sub_cnt)
  FROM (
    SELECT sf.website_id, sf.user_id, COUNT(*) AS sub_cnt
    FROM fact_visits sf
    GROUP BY sf.website_id, sf.user_id
  ) t
  WHERE t.website_id = w.website_id
)
ORDER BY visits DESC
LIMIT 25;

-- ── Q12: Average visits per user per day ─────────────────
SELECT
  u.user_name,
  COUNT(DISTINCT d.visit_date) AS active_days,
  COUNT(*)                     AS total_visits,
  ROUND(COUNT(*) / COUNT(DISTINCT d.visit_date), 2) AS avg_visits_per_day
FROM fact_visits f
JOIN dim_user    u ON f.user_id = u.user_id
JOIN dim_date    d ON f.date_id = d.date_id
GROUP BY u.user_id, u.user_name
ORDER BY avg_visits_per_day DESC;
