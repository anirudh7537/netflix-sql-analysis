# Netflix Movies and TV Shows Data Analysis using SQL (MySQL)

## Overview

This project is a SQL analysis of Netflix's movies and TV shows catalog, written in **MySQL**. It answers 15 business questions about content types, ratings, countries, genres, directors, actors, and content categorization. The README explains the objectives, the dataset, each query, the limitations, and the conclusions.

## Objectives

- Analyze the distribution of content types (movies vs TV shows).
- Identify the most common ratings for movies and TV shows.
- Analyze content by release year, country, genre, and duration.
- Explore content by director and cast.
- Categorize content using keywords found in descriptions.

## Tech Stack

- **Database:** MySQL 8.0 or later (the country query uses `JSON_TABLE` and the rating query uses window functions)
- **Tool:** MySQL Workbench (or any MySQL client)
- **Dataset:** Netflix Movies and TV Shows dataset from Kaggle

## Dataset Schema

```sql
DROP TABLE IF EXISTS netflix_titles;
CREATE TABLE netflix_titles
(
    show_id      VARCHAR(5),
    type         VARCHAR(10),
    title        VARCHAR(250),
    director     VARCHAR(550),
    `cast`       VARCHAR(1050),
    country      VARCHAR(550),
    date_added   VARCHAR(55),
    release_year INT,
    rating       VARCHAR(15),
    duration     VARCHAR(15),
    listed_in    VARCHAR(250),
    description  VARCHAR(550)
);

RENAME TABLE netflix_titles TO netflix;
```

## Data Cleaning

Empty strings are converted to `NULL` so that missing values can be detected with `IS NULL`.

```sql
UPDATE netflix
SET
    director    = NULLIF(TRIM(director), ''),
    `cast`      = NULLIF(TRIM(`cast`), ''),
    country     = NULLIF(TRIM(country), ''),
    date_added  = NULLIF(TRIM(date_added), ''),
    rating      = NULLIF(TRIM(rating), ''),
    duration    = NULLIF(TRIM(duration), ''),
    listed_in   = NULLIF(TRIM(listed_in), ''),
    description = NULLIF(TRIM(description), '');
```

## Business Problems and Solutions

### 1. Count the Number of Movies vs TV Shows

```sql
SELECT
    type,
    COUNT(*) AS total_content
FROM netflix
GROUP BY 1;
```

**Objective:** Determine the distribution of content types on Netflix.

### 2. Find the Most Common Rating for Movies and TV Shows

```sql
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
```

**Objective:** Identify the most frequently occurring rating for each type of content.

### 3. List All Movies Released in a Specific Year (e.g., 2020)

```sql
SELECT *
FROM netflix
WHERE release_year = 2020;
```

**Objective:** Retrieve all content released in a specific year.

### 4. Find the Top 5 Countries with the Most Content on Netflix

```sql
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
```

**Objective:** Identify the top 5 countries with the highest number of content items. Because one title can list several countries, the query splits the comma-separated values into separate rows.

### 5. Identify the Longest Movie

```sql
SELECT *
FROM netflix
WHERE type = 'Movie'
ORDER BY CAST(SUBSTRING_INDEX(duration, ' ', 1) AS UNSIGNED) DESC
LIMIT 1;
```

**Objective:** Find the movie with the longest duration (in minutes).

### 6. Find Content Added in the Last 5 Years

```sql
SELECT *
FROM netflix
WHERE STR_TO_DATE(TRIM(date_added), '%M %d, %Y')
      >= DATE_SUB('2024-01-01', INTERVAL 5 YEAR);
```

**Objective:** Retrieve content added to Netflix in the last 5 years. A fixed reference date (`2024-01-01`) is used so that the results stay the same whenever the query is run.

### 7. Find All Movies/TV Shows by Director 'Rajiv Chilaka'

```sql
SELECT *
FROM netflix
WHERE FIND_IN_SET('Rajiv Chilaka', REPLACE(director, ', ', ',')) > 0;
```

**Objective:** List all content directed by 'Rajiv Chilaka', including titles with several directors.

### 8. List All TV Shows with More Than 5 Seasons

```sql
SELECT *
FROM netflix
WHERE type = 'TV Show'
  AND CAST(SUBSTRING_INDEX(TRIM(duration), ' ', 1) AS UNSIGNED) > 5
  AND duration LIKE '%Seasons%';
```

**Objective:** Identify TV shows with more than 5 seasons.

### 9. Find the Top 10 Most Common Genre Combinations on Netflix

```sql
SELECT
    listed_in AS genre,
    COUNT(*) AS total_content
FROM netflix
WHERE listed_in IS NOT NULL
GROUP BY listed_in
ORDER BY total_content DESC
LIMIT 10;
```

**Objective:** Find which genre combinations appear most often.

### 10. Find the Top 5 Release Years for Indian Content

```sql
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
```

**Objective:** Rank the release years by each year's share (percentage) of all Indian content, and return the top 5.

### 11. List All Movies that are Documentaries

```sql
SELECT *
FROM netflix
WHERE listed_in LIKE '%Documentaries';
```

**Objective:** Retrieve all content classified as documentaries.

### 12. Find All Content Without a Director

```sql
SELECT *
FROM netflix
WHERE director IS NULL
   OR TRIM(director) = '';
```

**Objective:** List content that does not have a director.

### 13. Count Movies Featuring Salman Khan in the Last 10 Years

```sql
SELECT COUNT(*) AS total_movies
FROM netflix
WHERE `type` = 'Movie'
  AND `cast` LIKE '%Salman Khan%'
  AND release_year >= YEAR(CURDATE()) - 10;
```

**Objective:** Count the movies featuring 'Salman Khan' released in the last 10 years.

### 14. Find the Top 10 Cast Lists in Indian Netflix Content

```sql
SELECT
    `cast`,
    COUNT(*) AS total_content
FROM netflix
WHERE country = 'India'
  AND `cast` IS NOT NULL
GROUP BY `cast`
ORDER BY total_content DESC
LIMIT 10;
```

**Objective:** Find the cast entries that appear most often in Indian content.

### 15. Categorize Content Using 'Kill' and 'Violence' Keywords

```sql
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
```

**Objective:** Label content as 'Bad' if its description contains 'kill' or 'violence', and 'Good' otherwise. Then count the items in each category.

## SQL Concepts Used

- Aggregate functions: `COUNT`, `ROUND`
- Grouping and sorting: `GROUP BY`, `ORDER BY`, `LIMIT`
- Common Table Expressions (CTEs) and window functions: `WITH`, `RANK() OVER (PARTITION BY ...)`
- String functions: `TRIM`, `NULLIF`, `SUBSTRING_INDEX`, `REPLACE`, `FIND_IN_SET`, `LIKE`
- Date functions: `STR_TO_DATE`, `DATE_SUB`, `CURDATE`, `YEAR`
- JSON function: `JSON_TABLE` (to split comma-separated values)
- Conditional logic: `CASE WHEN`
- Subqueries

## How to Run

1. Download the Netflix dataset from Kaggle.
2. Create the table using the schema above and import the CSV file (for example, with the Table Data Import Wizard in MySQL Workbench).
3. Run the data cleaning script.
4. Run the queries one by one from `netflix_analysis.sql`.

## Findings and Conclusion

- **Content distribution:** The dataset contains both movies and TV shows, and movies make up the larger share.
- **Ratings:** The most common rating for each content type shows the audience Netflix targets most.
- **Geography:** The top countries and the yearly release share for India show where Netflix content comes from.
- **Genres:** Grouping by genre combination shows which kinds of content are most common.
- **Categorization:** Keyword-based labels give a quick, rough view of how much content mentions violence.

> Add your own numbers here after running the queries (for example, the exact movie and TV show counts and the top 5 countries).

## Limitations

- **Keyword matching (Query 15)** can produce false positives, because "kill" also matches words like "skill". It also ignores context and sentiment.
- **Query 10** uses `country = 'India'`, so titles that list several countries (for example, "India, United States") are not counted. Its column `avg_release` is a percentage share, not an average.
- **Query 11** matches only genres that end with "Documentaries" and does not filter by type, so it can include TV documentaries.
- **Query 14** groups by the full cast string, so it returns the most repeated cast lists, not individual actors.
- **Queries 6 and 13** depend on a reference date. Query 6 uses a fixed date, while Query 13 uses the current date, so its result changes over time.

## Future Improvements

- Split the cast column into individual actors (as done for countries in Query 4) to rank single actors.
- Replace `LIKE` with a regular expression using word boundaries (`REGEXP '\\bkill\\b'`) for Query 15.
- Build a dashboard in Excel or Power BI from the query results.

## Author

**Anirudh**
B.Tech Computer Science and Engineering, Global Institute of Technology, Jaipur
Specializing in Data Analytics and Machine Learning

This project is part of my data analyst portfolio. Feedback and suggestions are welcome.

- GitHub: [anirudh7537](https://github.com/anirudh7537)
- LinkedIn: _add your profile link here_

## License

This project is licensed under the MIT License.
