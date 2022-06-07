--Data Cleaning--

SELECT *
FROM [GunViolence].[dbo].[all_incidents]
ORDER BY incident_id;


SELECT *
FROM [GunViolence].[dbo].[all_incidents]
WHERE state IS NULL OR city IS NULL  --Checking for any null incident locations
ORDER BY incident_id

--Seeing if there are any mass shootings that are not in the All_Incidents table.
SELECT ms.incident_id
FROM all_incidents i
RIGHT JOIN mass_shootings ms
	ON i.incident_id = ms.Incident_ID
WHERE ms.incident_id NOT IN (SELECT Incident_ID FROM all_incidents);
-- There are four.

SELECT *
FROM [GunViolence].[dbo].[mass_shootings]
WHERE incident_id IN (946496, 2172621, 326792, 1974755);
--I'm going to add these Mass Shootings into the all_incidents table

INSERT INTO all_incidents
SELECT *
FROM mass_shootings
WHERE incident_id IN (946496, 2172621, 326792, 1974755)

--Check that Incident_IDs are unique
SELECT
	incident_id
FROM all_incidents
GROUP BY incident_id
HAVING COUNT(*)>1
--There are 946 duplicate inicident_id.  Let's see why.

SELECT *
FROM all_incidents
WHERE incident_id IN
	(SELECT
		incident_id
	FROM all_incidents
	GROUP BY incident_id
	HAVING COUNT(*)>1)
ORDER BY 1
--This shows that these entries are true duplicates with the occasional address discrepency.

--I will remove the duplicates:
WITH dup AS
(
	SELECT
		*,
		ROW_NUMBER() OVER (PARTITION BY incident_id ORDER BY incident_id) AS rn
	FROM all_incidents
)
DELETE
FROM dup
WHERE rn > 1
;
--I'll look at mass_shootings table as well
SELECT
	incident_id
FROM mass_shootings
GROUP BY incident_id
HAVING COUNT(*)>1
--No duplicates


--Analysis--

--How many gun incidents per year?
SELECT 
	Year(date) AS Year,
	COUNT(*) AS incident_count
FROM all_incidents
GROUP BY Year(date)
ORDER BY Year(date)
--2022 doesn't reflect the whole year

SELECT
	*,
	(SELECT MIN(date) FROM all_incidents) AS min_date,
	(SELECT MAX(date) FROM all_incidents) AS max_date
FROM all_incidents
WHERE year(date) = 2013
ORDER BY date;
--2013 Does reflect the entire year, but still shows much fewer incidents.
--Something to explore later, but for now we'll filter out 2013 from our analysis.

DELETE FROM all_incidents
WHERE year(date) = 2013;  --Deleted all rows from table.  Focusing on 2014-2021


--Summary table of totals/averages

SELECT
	Year(date) AS Year,
	COUNT(incident_id) AS incident_count,
	SUM(n_killed) AS Total_killed,
	SUM(n_injured) AS Total_injured,
	MAX(n_killed) AS max_killed,
	MAX(n_injured) AS max_injured,  --Max killed and injured are not necessarily from the same event
	ROUND(AVG(CAST(n_killed as float)), 2) AS Avg_killed,
	ROUND(AVG(CAST(n_injured as float)), 2) AS Avg_injured  
FROM all_incidents
GROUP BY Year(date)
ORDER BY Year(date)
--It looks like the number of people killed or injured from gun violence has increased since 2014
--The average number killed or injured is also rising.

--For each year, what is the average number of:
--Daily incidents, daily injured, and daily killed
SELECT
	YEAR(date) AS Year,
	avg(count) AS Avg_daily_incidents,
	AVG(Total_injured) AS Avg_daily_injured,
	AVG(Total_killed) AS Avg_daily_killed
FROM (
	SELECT 
		date,
		COUNT(incident_id) as count,
		SUM(n_injured) AS Total_injured,
		SUM(n_killed) AS Total_killed
	FROM all_incidents
	Group BY date
	) a
GROUP BY YEAR(date)
ORDER BY Year(date);


--How many incidents in each month, filtering out 2022?
Select
	MONTH(date) AS month,
	COUNT(incident_id) AS incident_count
FROM all_incidents
WHERE YEAR(date) <> 2022  --2022 isn't a full year
GROUP BY MONTH(date)
ORDER BY incident_count desc
--This shows that there are more gun violence instances in the Summer months than Winter

--What days were the worst for gun violence incidents?  Count, Sum Injured, Sum Killed
--Top 10 dates ranked by its Sum of injured and killed
SELECT
	date,
	incident_count,
	total_victims
FROM (
	SELECT
		rank() OVER (ORDER BY (SUM(n_injured) + SUM(n_killed)) desc) AS rank,
		date,
		COUNT(incident_id) AS incident_count,
		(SUM(n_injured) + SUM(n_killed)) AS total_victims
	FROM all_incidents
	GROUP BY date
) a
WHERE rank <= 10
--2017-10-01 is interesting because the number of incidents is must lower,
--but the Total injured or killed is higher.

--Let's look at mass shootings on that day
SELECT *
FROM mass_shootings
WHERE Incident_Date = '2017-10-01'
--This was the date of the Las Vegas mass shooting by Stephen Paddock
--Was this the most violent event?

SELECT 
	Incident_ID,
	Incident_date,
	City_Or_County,
	(SUM(injured) + SUM(killed)) AS Total_victims
FROM mass_shootings
GROUP BY Incident_ID, Incident_Date, City_Or_County
ORDER BY Total_victims desc
--The Las Vegas shooting had the most victims (injured + killed)

--Curious about percentage of incidents had no victims (noone was injured or killed)
SELECT
	ROUND(no_victims/all_incidents, 4) * 100 AS victimless_percent
FROM
(
	SELECT 
		CAST(COUNT(*) as float) AS all_incidents,
		CAST((
			SELECT COUNT(*)
			FROM all_incidents
			WHERE 
				n_killed = 0
				AND n_injured = 0
		) as float) AS no_victims
	FROM all_incidents
) a


--What percentage of all incidents were mass shootings?
--count(mass_shootings)/count(all_incidents)

SELECT
	ROUND(
		((CAST(count(b.incident_id) as float))/
		(CAST(count(a.incident_id) as float)))
		, 4) * 100 AS mass_shooting_percent
FROM all_incidents a
LEFT JOIN mass_shootings b
	ON a.incident_id = b.Incident_ID


--Which cities had the highest deaths to gun violence?
SELECT
	city,
	SUM(n_killed) as total_killed
FROM all_incidents
GROUP BY city
ORDER BY 2 desc
--What would be interesting to add to this analysis is population data
--to look at victims per capita

--Narrowing it down to New York
SELECT
	city,
	SUM(n_killed) AS total_killed,
	SUM(n_injured) AS total_injured,
	SUM(n_injured) + SUM(n_killed) AS total_victims
FROM all_incidents
WHERE state = 'New York'
GROUP BY city
ORDER BY total_victims desc

--Number of incidents over time (Months)
SELECT 
	MONTH(a.date) AS month,
	YEAR(a.date) AS year,
	COUNT(a.incident_id) as incident_count,  --includes mass shootings
	COUNT(b.incident_ID) as mass_count
FROM all_incidents a
LEFT JOIN mass_shootings b
	ON a.incident_id = b.Incident_ID
GROUP BY MONTH(date), year(date)
ORDER by 2, 1



--This query finds the max month and day in the dataset and looks at the total killed and injured
--for each year up to that max month/day.
--The purpose is to see how 2022 data looks so far compared to previous years at this time.
SELECT 
	YEAR(date) AS year, 
	SUM(n_killed) AS total_killed, 
	SUM(n_injured) AS total_injured
FROM all_incidents
WHERE
	MONTH(date) <
	(
		SELECT MAX(MONTH(date)) AS max_month
		FROM all_incidents
		WHERE date IN (SELECT MAX(date) FROM all_incidents)
	)
	AND DAY(date) <
	(
		SELECT MAX(DAY(date)) AS max_day
		FROM all_incidents
		WHERE date IN (SELECT MAX(date) FROM all_incidents)
	)
GROUP BY YEAR(date)