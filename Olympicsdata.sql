--Added New column for Name
--ALTER table olympics_history ADD New_name nvarchar(150);

--Moved everything from Name to New_name
--UPDATE olympics_history SET New_name = CAST(Name AS nvarchar(150));

--Dropped column Name
--ALTER table olympics_history
--DROP COLUMN Name;

--Updated table with Trim(Name) to remove leading spaces on some names.
--UPDATE olympics_history SET Name = TRIM(Name)

--Number of athletes grouped by the Games
SELECT 
	Games, 
	Count (distinct ID) AS Num_of_athletes
FROM olympics_history
WHERE Season = 'Winter'
GROUP BY Games
ORDER BY Games DESC;

SELECT 
	Games, 
	Count (distinct ID) AS Num_of_athletes
FROM olympics_history
WHERE Season = 'Summer'
GROUP BY Games
ORDER BY Games DESC;
--The number of athletes participating has increased
--for both Summer and Winter games over time.


--Number of Teams that participated in Summer Games.
--Notice 2 years between 1904, 1906, 1908
SELECT
	Year, 
	COUNT(Distinct Team) AS Summer_participants
FROM olympics_history
WHERE Season = 'Summer'
GROUP BY Year
ORDER BY Year DESC
;

--Number of Teams that participated in Winter Games.
SELECT 
	Year,
	COUNT(Distinct Team) AS Winter_participants
FROM olympics_history
WHERE Season = 'Winter'
GROUP BY Year
ORDER BY Year DESC
;
--There was a boycott in 1980 which was why there was decrease in teams that year.

--Number of athletes by Sport
SELECT TOP 20
	Sport, 
	COUNT(distinct ID) AS num_of_athletes
FROM olympics_history
GROUP BY Sport
ORDER BY COUNT(ID) DESC;

--Number of athletes by Event
SELECT TOP 20
	Event, 
	Sport, 
	COUNT( distinct ID) AS num_of_athletes
FROM olympics_history
GROUP BY Event, Sport
ORDER BY COUNT(ID) DESC;

--Number of athletes by Year
SELECT TOP 20 
	Games,
	COUNT(distinct ID) AS num_of_athletes
FROM olympics_history
GROUP BY Games
ORDER BY COUNT(ID) DESC;


--Who won gold and silver medal in each year Womens Basketball was played?
SELECT 
	G.year, 
	G.gold, 
	S.silver
FROM
(
	SELECT year, region AS gold 
	FROM olympics_history
		LEFT JOIN olympics_history_noc_regions
			 ON olympics_history.noc = olympics_history_noc_regions.noc
	WHERE sport = 'Basketball' and sex = 'F' and medal = 'Gold'
	GROUP BY year, region) G,
(
	SELECT year, region AS silver 
	FROM olympics_history
		LEFT JOIN olympics_history_noc_regions
			ON olympics_history.noc = olympics_history_noc_regions.noc
	WHERE sport = 'Basketball' and sex = 'F' and medal = 'Silver'
	GROUP BY year, region) S
WHERE G.year = S.year
ORDER BY year DESC


--List of Athletes with Gold Metals
SELECT olympics_history.Name, Num_of_gold
FROM olympics_history
JOIN (
	SELECT ID, COUNT(Medal) AS Num_of_gold
	FROM olympics_history
	WHERE Medal = 'Gold'
	GROUP BY ID ) AS o
ON olympics_history.ID = o.ID
GROUP BY olympics_history.Name, Num_of_gold
ORDER BY Num_of_gold DESC
;

--List of Athletes with Silver Metals
SELECT olympics_history.Name, Num_of_silver
FROM olympics_history
JOIN (
	SELECT ID, COUNT(Medal) AS Num_of_silver
	FROM olympics_history
	WHERE Medal = 'Silver'
	GROUP BY ID ) AS o
ON olympics_history.ID = o.ID
GROUP BY olympics_history.Name, Num_of_silver
ORDER BY Num_of_silver DESC
;

--List of Athletes with Bronze Metals
SELECT olympics_history.Name, Num_of_bronze
FROM olympics_history
JOIN (
	SELECT ID, COUNT(Medal) AS Num_of_bronze
	FROM olympics_history
	WHERE Medal = 'Bronze'
	GROUP BY ID ) AS o
ON olympics_history.ID = o.ID
GROUP BY olympics_history.Name, Num_of_bronze
ORDER BY Num_of_bronze DESC
;


--List of Athletes with No medals
SELECT olympics_history.Name, Num_of_NA
FROM olympics_history
JOIN (
	SELECT ID, COUNT(Medal) AS Num_of_NA
	FROM olympics_history
	WHERE Medal = 'NA'
	GROUP BY ID ) AS o
ON olympics_history.ID = o.ID
GROUP BY olympics_history.Name, Num_of_NA
ORDER BY Num_of_NA DESC
;


--Number of event slots by gender
SELECT Sex, Count(*)
FROM olympics_history
GROUP BY Sex
;


--Difference between number of IDs and distinct names.
--This is to see how many athletes share the name with other athletes
SELECT
	COUNT(DISTINCT(ID)) AS Distinct_ID,
	COUNT(DISTINCT(Name)) AS Distinct_Name,
	(COUNT(DISTINCT(ID)) - COUNT(DISTINCT(Name))) AS Diff
FROM olympics_history


-- List of atheletes with the same name, but different IDs
SELECT o2.Name, COUNT(ID)
FROM (
	SELECT o1.ID, o1.Name
	FROM olympics_history o1
	GROUP BY o1.ID, o1.Name
	) AS o2
GROUP BY o2.Name
HAVING COUNT(ID) > 1
ORDER BY COUNT(ID) DESC
;


--Number of slots by sport.  Not distinct athletes.
SELECT Sport, Count(ID)
FROM olympics_history
GROUP BY Sport
ORDER BY COUNT(ID) DESC;

--Average age of athlete for each sport
SELECT TOP (20) Sport, AVG(CAST(Age AS INT)) AS avg_age
FROM olympics_history
GROUP BY Sport
ORDER BY avg_age DESC
;


SELECT *
FROM olympics_history
WHERE Sport = 'Roque'
;
--Roque has the highest average age, but there were only four participants ever.


--Number of athletes in Summer Games over time
SELECT Games, COUNT(DISTINCT ID) AS num_of_athletes
FROM olympics_history
WHERE Season = 'Summer'
GROUP BY Games
ORDER BY Games
;


--Which year saw the highest number of countries participate?
SELECT TOP 1 Year, COUNT(DISTINCT NOC) AS num_of_nations
FROM olympics_history
GROUP BY Year
ORDER BY num_of_nations DESC;

--Which year saw the lowest no of countries participate?
SELECT TOP 1 Year, COUNT(DISTINCT NOC) AS num_of_nations
FROM olympics_history
GROUP BY Year
ORDER BY num_of_nations;

--Which nation has participated in all of the olympic games?
WITH
	tot AS (
	SELECT COUNT(DISTINCT(Games)) AS tot_games
	FROM olympics_history
	),

	num_of_games AS (
	SELECT NOC, COUNT(DISTINCT(Games)) AS num_of_games
	FROM olympics_history
	GROUP BY NOC
	)

SELECT olympics_history_noc_regions.region, tot.tot_games
FROM tot
	JOIN num_of_games
		ON num_of_games = tot_games
	JOIN olympics_history_noc_regions
		ON olympics_history_noc_regions.NOC = num_of_games.NOC;


--Identify the sport which was played in all summer olympics.

WITH s1 AS (
	SELECT
		DISTINCT Sport, 
		COUNT(DISTINCT(Games)) AS c1
	FROM olympics_history
	WHERE Season = 'Summer'
	GROUP BY Sport
	),

s2 AS (
	SELECT COUNT(DISTINCT(Games)) AS c2
	FROM olympics_history
	WHERE Season = 'Summer'
	)

SELECT Sport, c2 AS num_of_games
FROM s1
JOIN s2
ON s1.c1 = s2.c2


--Which Sports were just played only once in the olympics?

SELECT 
	Sport, 
	COUNT(DISTINCT(Games)) AS num_of_games
FROM olympics_history
GROUP BY Sport
HAVING COUNT(DISTINCT(Games)) = 1


--What is the total number of sports played in each olympic games?

SELECT
	Games,
	COUNT(DISTINCT(Sport)) AS no_of_sports
FROM olympics_history
GROUP BY Games
ORDER BY no_of_sports DESC, Games

--Who are the oldest athletes to win a gold medal?
Select *
FROM olympics_history AS o1
JOIN (
	SELECT MAX(Age) AS a2
	FROM olympics_history
	WHERE Medal = 'Gold'
	) AS o2
ON o1.Age = o2.a2
WHERE Medal = 'Gold'


--What is the Ratio of male and female athletes who participated in all olympic games?


SELECT (
SELECT CAST(COUNT(DISTINCT(ID)) AS FLOAT) AS c1
FROM olympics_history
WHERE Sex = 'M'
)
/
(SELECT CAST(COUNT(DISTINCT(ID)) AS FLOAT) AS c2
FROM olympics_history
WHERE Sex = 'F')
;
--Almost three times more males have participated in the Olympics.


--Who are the top 5 athletes who have won the most gold medals?

WITH s1 AS (
SELECT DISTINCT TOP 5 COUNT(Medal) AS c1
FROM olympics_history
WHERE Medal = 'Gold'
GROUP BY Name
ORDER BY COUNT(Medal) DESC
),

s2 AS (
SELECT Name, COUNT(Medal) AS num_of_golds
FROM olympics_history
WHERE Medal = 'Gold'
GROUP BY Name
)

SELECT s2.Name, s2.num_of_golds
FROM s2
JOIN s1
ON s2.num_of_golds = s1.c1
ORDER BY num_of_golds DESC;


--Who are the top 5 athletes who have won the most medals (gold/silver/bronze)?

WITH s1 AS (
SELECT DISTINCT TOP 5 COUNT(Medal) AS c1
FROM olympics_history
WHERE Medal <> 'NA'
GROUP BY Name
ORDER BY COUNT(Medal) DESC
),

s2 AS (
SELECT Name, COUNT(Medal) AS num_of_medals
FROM olympics_history
WHERE Medal <> 'NA'
GROUP BY Name
)

SELECT Name, num_of_medals
FROM s2
JOIN s1
ON s1.c1 = s2.num_of_medals
ORDER BY num_of_medals DESC
;


--Number of Medals by age

	SELECT age, Count(*) AS num_of_medals
	FROM olympics_history
	WHERE age <> 'NA' AND medal <> 'NA'
	GROUP BY age


--List down total gold, silver and bronze medals won by each country corresponding to each olympic games.
SELECT
	Games,
	Region, 
	SUM(CASE medal
		WHEN 'Gold' THEN 1
		ELSE 0
		END) AS num_gold,
	SUM(CASE medal
		WHEN 'Silver' THEN 1
		ELSE 0
		END) AS num_silver,
	SUM(CASE medal
		WHEN 'Bronze' THEN 1
		ELSE 0
		END) AS num_bronze
FROM olympics_history
JOIN olympics_history_noc_regions
ON olympics_history.NOC = olympics_history_noc_regions.NOC
GROUP BY Games, Region
ORDER BY Games, Region


--What is the average height, weight, age of each 'Game'?
SELECT
	Distinct Games,
	ROUND(AVG(CAST(Height AS float)) OVER(PARTITION BY Games),2) AS [Average Height],
	ROUND(AVG(CAST(Weight AS float)) OVER(PARTITION BY Games),2) AS [Average Weight],
	ROUND(AVG(CAST(Age AS float)) OVER(PARTITION BY Games),2) AS [Average Age]
FROM olympics_history
WHERE Height <> 'NA' AND Weight <> 'NA' AND AGE <> 'NA'
ORDER BY Games;



--List of each region along with the sport that that region has acheived the most medals in
SELECT NOC, Sport, Medal_Count
FROM
(
SELECT NOC, Sport, COUNT(Medal) AS Medal_Count,
rank() OVER (PARTITION BY NOC ORDER BY COUNT(Medal) DESC) AS Rank
FROM olympics_history
WHERE Medal <> 'NA'
GROUP BY NOC, Sport
) a
WHERE Rank <= 1
ORDER BY Medal_Count DESC