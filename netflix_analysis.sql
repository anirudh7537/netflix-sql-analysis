DROP TABLE IF EXISTS netflix_titles;
CREATE TABLE netflix_titles
(
    show_id      VARCHAR(5),
    type         VARCHAR(10),
    title        VARCHAR(250),
    director     VARCHAR(550),
    casts        VARCHAR(1050),
    country      VARCHAR(550),
    date_added   VARCHAR(55),
    release_year INT,
    rating       VARCHAR(15),
    duration     VARCHAR(15),
    listed_in    VARCHAR(250),
    description  VARCHAR(550)
);
RENAME TABLE netflix_titles TO netflix;

UPDATE netflix
SET
    director = NULLIF(TRIM(director), ''),
    `cast` = NULLIF(TRIM(`cast`), ''),
    country = NULLIF(TRIM(country), ''),
    date_added = NULLIF(TRIM(date_added), ''),
    rating = NULLIF(TRIM(rating), ''),
    duration = NULLIF(TRIM(duration), ''),
    listed_in = NULLIF(TRIM(listed_in), ''),
    description = NULLIF(TRIM(description), '');
SELECT DISTINCT
    type
FROM
    netflix_titles;

Select * from netflix;


-- 1. Count the Number of Movies vs TV Shows
SELECT 
    type,
    COUNT(*) as total_content
FROM netflix
GROUP BY 1;

-- 2. Find the Most Common Rating for Movies and TV Shows
SELECT 
    type, rating
FROM
    netflix;
    
select type,rating,count(*) from netflix group by 1, 2 order by 1,3 desc;    

WITH RatingCounts AS (
    SELECT
        `type`,
        rating,
        COUNT(*) AS rating_count
    FROM netflix
    GROUP BY `type`, rating
),
RankedRatings AS (
    SELECT
        `type`,
        rating,
        rating_count,
        RANK() OVER (
            PARTITION BY `type`
            ORDER BY rating_count DESC
        ) AS rating_rank
    FROM RatingCounts
)
SELECT
    `type`,
    rating AS most_frequent_rating
FROM RankedRatings
WHERE rating_rank = 1;


-- 3.  List All Movies Released in a Specific Year (e.g., 2020)
-- filter 2020
-- movies
SELECT 
    *
FROM
    netflix
WHERE
    release_year = 2020;
    
-- 4. Find the Top 5 Countries with the Most Content on Netflix
SELECT
    TRIM(j.country) AS country,
    COUNT(*) AS total_content
FROM netflix AS n
JOIN JSON_TABLE(
    CONCAT('["', REPLACE(n.country, ',', '","'), '"]'),
    '$[*]' COLUMNS (
        country VARCHAR(255) PATH '$'
    )
) AS j
WHERE n.country IS NOT NULL
  AND TRIM(j.country) <> ''
GROUP BY TRIM(j.country)
ORDER BY total_content DESC
LIMIT 5;    
    
-- 5. Identify the Longest Movie
 SELECT *
FROM netflix
WHERE type = 'Movie'
ORDER BY CAST(SUBSTRING_INDEX(duration, ' ', 1) AS UNSIGNED) DESC limit 1;

-- 6. Find Content Added in the Last 5 Years
SELECT *
FROM netflix
WHERE STR_TO_DATE(TRIM(date_added), '%M %d, %Y')
      >= DATE_SUB('2024-01-01', INTERVAL 5 YEAR);
-- 7. Find All Movies/TV Shows by Director 'Rajiv Chilaka'
SELECT 
    *
FROM
    netflix
WHERE
    FIND_IN_SET('Rajiv Chilaka',
            REPLACE(director, ', ', ',')) > 0;


-- 8. List All TV Shows with More Than 5 Seasons 
SELECT 
    *
FROM
    netflix
WHERE
    type = 'Tv Show'
        AND CAST(SUBSTRING_INDEX(TRIM(duration), ' ', 1) AS UNSIGNED) > 5
        AND duration LIKE '%Seasons%';
        
        
### 9. Find the Top 10 Most Common Genre Combinations on Netflix


SELECT
    listed_in AS genre,
    COUNT(*) AS total_content
FROM netflix
WHERE listed_in IS NOT NULL
GROUP BY listed_in
ORDER BY total_content DESC
LIMIT 10;

-- 10.Find each year and the average numbers of content release in India on netflix.
-- Find the top 5 release years for Indian Netflix content

SELECT
    country,
    release_year,
    COUNT(show_id) AS total_release,
    ROUND(
        COUNT(show_id) * 100.0 /
        (SELECT COUNT(show_id)
         FROM netflix
         WHERE country = 'India'),
        2
    ) AS avg_release
FROM netflix
WHERE country = 'India'
GROUP BY country, release_year
ORDER BY avg_release DESC
LIMIT 5;


-- 11. List All Movies that are Documentaries
SELECT * 
FROM netflix
WHERE listed_in LIKE '%Documentaries';

-- 12. Find All Content Without a Director

SELECT *
FROM netflix
WHERE director IS NULL
   OR TRIM(director) = '';
   
   
-- 13. Count Movies Featuring Salman Khan in the Last 10 Years
SELECT COUNT(*) AS total_movies
FROM netflix
WHERE `type` = 'Movie'
  AND `cast` LIKE '%Salman Khan%'
  AND release_year >= YEAR(CURDATE()) - 10;   
  
-- 14. Find the Top 10 Actors in Indian Netflix Content
SELECT
    `cast`,
    COUNT(*) AS total_content
FROM netflix
WHERE country = 'India'
  AND `cast` IS NOT NULL
GROUP BY `cast`
ORDER BY total_content DESC
LIMIT 10;

-- 15. Categorize Content Using “Kill” and “Violence” Keywords
SELECT
    CASE
        WHEN LOWER(description) LIKE '%kill%'
          OR LOWER(description) LIKE '%violence%'
        THEN 'Bad'
        ELSE 'Good'
    END AS category,
    COUNT(*) AS content_count
FROM netflix
GROUP BY category;