SELECT *
FROM Movies..movie_data

SELECT *
FROM Movies..my_ratings

SELECT DISTINCT original_language
FROM Movies..movie_data

--create new table with relevant columns

SELECT * INTO movie_data_clean
FROM (
		SELECT	genres, movie_title, original_language, popularity, production_countries, runtime, spoken_languages, vote_average, vote_count, year_released
		FROM Movies..movie_data)a

SELECT *
FROM Movies..movie_data_clean

--remove quotation marks from columns "genre" "production_countries", "spoken_languages"

UPDATE Movies..movie_data_clean
SET genres = REPLACE(genres, '"', ''),
	production_countries = REPLACE(production_countries, '"', ''),
	spoken_languages = REPLACE(spoken_languages, '"', '')

--remove square brackets from columns "genre" "production_countries", "spoken_languages"
	
UPDATE 	Movies..movie_data_clean
SET  genres = REPLACE(genres, '[', ''),
	production_countries = REPLACE(production_countries, '[', ''),
	spoken_languages = REPLACE(spoken_languages, '[', '')

UPDATE 	Movies..movie_data_clean
SET  genres = REPLACE(genres, ']', ''),
	production_countries = REPLACE(production_countries, ']', ''),
	spoken_languages = REPLACE(spoken_languages, ']', '')


--create new table for my ratings with relevant columns and data format changed

SELECT * INTO my_ratings_clean
FROM(
	SELECT CONVERT(date, Date) as rating_date, Name, Year, Rating
	FROM Movies..my_ratings)b

SELECT *
FROM Movies..my_ratings_clean
ORDER BY rating_date

--populate my ratings table with more information about the movies 


SELECT a.*, b.*
	FROM Movies..my_ratings_clean a
	JOIN Movies..movie_data_clean b
		ON a.Name=b.movie_title
		AND a.Year=b.year_released
		--AND a.Year<>b.year_released
		ORDER BY Name


--create new table 

SELECT * INTO my_ratings_tempt
	FROM(SELECT a.*, b.*
	FROM Movies..my_ratings_clean a
	JOIN Movies..movie_data_clean b
		ON a.Name=b.movie_title
		AND a.Year=b.year_released
		--AND a.Year<>b.year_released
	)d

SELECT *
FROM dbo.my_ratings_tempt
ORDER BY name

--remove reduntant columns

ALTER TABLE dbo.my_ratings_tempt
DROP COLUMN movie_title, year_released  


--left join to check movies without information


SELECT a.*, b.*
	FROM Movies..my_ratings_clean a
	LEFT JOIN Movies..movie_data_clean b
		ON a.Name=b.movie_title
		AND a.Year=b.year_released
		--AND a.Year<>b.year_released

--spoken languages column: replace enumeration of languages to 'multiple languages' 

SELECT DISTINCT spoken_languages
FROM dbo.my_ratings_tempt

SELECT * INTO my_ratings_analysis FROM(
	SELECT *,
	CASE
		WHEN spoken_languages NOT LIKE 'English' 
		AND spoken_languages NOT LIKE 'Italiano' 
	THEN 
		'Multiple Languages'
	ELSE 
		spoken_languages
	END AS 
		spoken_language
FROM 
	dbo.my_ratings_tempt)a

SELECT *
FROM dbo.my_ratings_analysis

ALTER TABLE dbo.my_ratings_analysis
DROP COLUMN spoken_languages

--genres column: pick the first genre to represent the movie

SELECT DISTINCT genres
FROM dbo.my_ratings_analysis

SELECT * INTO dbo.my_ratings_analysis1 FROM(
SELECT *,	
	CASE
		WHEN genres NOT LIKE 'Comedy'
		AND genres NOT LIKE 'Drama'
		AND genres NOT LIKE 'Western'
	THEN 
		SUBSTRING(genres, 1, CHARINDEX(',', genres)-1)
	ELSE
		genres	
	END as genre
FROM dbo.my_ratings_analysis)a

SELECT * FROM dbo.my_ratings_analysis1

ALTER TABLE dbo.my_ratings_analysis1
DROP COLUMN genres

--poduction_countries column: replace enumeration of countries to 'multiple countries' 

SELECT DISTINCT production_countries
FROM dbo.my_ratings_analysis1

SELECT * INTO my_ratings_analysis2 FROM(
	SELECT *,
	CASE
		WHEN production_countries NOT LIKE 'South Korea' 
		AND production_countries NOT LIKE 'Spain' 
		AND production_countries NOT LIKE 'United Kingdom' 
		AND production_countries NOT LIKE 'United States of America' 
	THEN 
		'Multiple Countries'
	ELSE 
		production_countries
	END AS 
		prod_countries
FROM 
	dbo.my_ratings_analysis1)a

ALTER TABLE dbo.my_ratings_analysis2
DROP COLUMN production_countries

--put personal and public rate on the same scale (1-10)

ALTER TABLE dbo.my_ratings_analysis2
ALTER COLUMN rating float(24)

SELECT * INTO dbo.my_ratings_analysis3
FROM(
	Select *, rating*2 AS personal_rating
	FROM dbo.my_ratings_analysis2)a

ALTER TABLE dbo.my_ratings_analysis3
DROP COLUMN rating

--change data types

ALTER TABLE dbo.my_ratings_analysis3
ALTER COLUMN personal_rating float(24)


ALTER TABLE dbo.my_ratings_analysis3
ALTER COLUMN public_rating float(24)


ALTER TABLE dbo.my_ratings_analysis3
ALTER COLUMN popularity float(24)

SELECT *
FROM Movies.dbo.my_ratings_analysis3

--add movie director data

SELECT * into add_movie_data
FROM(
	SELECT a.*, b.crew
	FROM Movies.dbo.budget_data a
	LEFT JOIN Movies.dbo.crew_data b
	ON a.id=b.id)a

ALTER TABLE dbo.crew_data
ALTER COLUMN id NVARCHAR(10)

SELECT * INTO dbo.add_movie_data2
from(SELECT
		*, 
		SUBSTRING(crew, CHARINDEX('Director name:', crew), CHARINDEX('pro', crew)) director
	FROM dbo.add_movie_data)a

SELECT SUBSTRING(director, 15, CHARINDEX('pro', director))
FROM dbo.add_movie_data2


SELECT * INTO dbo.add_movie_data4
FROM(
	SELECT
		*, 
		SUBSTRING(director, 16, CHARINDEX('pro', director)) director_name
	FROM dbo.add_movie_data2)d


SELECT * INTO dbo.add_movie_data3
FROM(
SELECT *, LEFT(director_name, CHARINDEX(' ', director_name,
							CHARINDEX(' ', director_name)+1)) movie_director
FROM dbo.add_movie_data4)a

UPDATE 	dbo.add_movie_data
SET  crew = REPLACE(crew, '''', '')


--add data about production_companies

UPDATE 	dbo.add_movie_data3
SET  production_companies = REPLACE(production_companies, '''', '')

SELECT * INTO dbo.add_movie_data5
FROM(
	SELECT *,
	SUBSTRING(production_companies, 9, CHARINDEX(',', production_companies)) pcompanies
	FROM dbo.add_movie_data3)a

UPDATE 	dbo.add_movie_data5
SET  pcompanies = REPLACE(pcompanies, ',', '')

SELECT *
FROM dbo.add_movie_data6

SELECT * INTO dbo.add_movie_data6
FROM(
SELECT *, LEFT(pcompanies, CHARINDEX(' id', pcompanies)) production_company
FROM dbo.add_movie_data5)a

--remove reduntant columns

ALTER TABLE dbo.add_movie_data6
DROP COLUMN production_companies, crew, director, director_name, pcompanies

--join tables to add the information

SELECT * INTO dbo.my_ratings_final
FROM(
	SELECT a.*, b.movie_director, b.budget, b.production_company
	FROM dbo.my_ratings_analysis3 a 
	JOIN dbo.add_movie_data6 b
	ON a.Name=b.original_title)a
	--order by year desc

SELECT *
FROM dbo.my_ratings_final
