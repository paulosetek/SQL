

--Table listing the school next to its District
Select ig.Institution_ID, 
	ig.ENTITY_NAME AS School, 
	og.ENTITY_NAME AS District,
	ig.ENTITY_CD
FROM (
	SELECT Institution_ID, ENTITY_CD, ENTITY_NAME
	FROM [Institution Grouping]
	WHERE GROUP_CODE = 6
	) ig
JOIN [Institution Grouping] og
ON LEFT(ig.ENTITY_CD, 8) = LEFT(og.ENTITY_CD,8)
WHERE og.GROUP_CODE = 5
;

--List of Counties (There's a better way to do this)
SELECT DISTINCT ENTITY_NAME
FROM [BEDS Day Enrollment]
WHERE LEFT(ENTITY_CD, 4) = 0000 AND RIGHT(ENTITY_CD, 4) = 0000
;
--This also lists NYC Public Schools as a county, so let's filter those out.
SELECT DISTINCT ENTITY_NAME
FROM [BEDS Day Enrollment]
WHERE LEFT(ENTITY_CD, 4) = 0000
AND RIGHT(ENTITY_CD, 4) = 0000
AND ENTITY_NAME NOT LIKE 'NYC%'
;


--Low, Average, High Need and its ENTITY_CD
SELECT ENTITY_NAME, ENTITY_CD
FROM [BEDS Day Enrollment]
WHERE RIGHT(ENTITY_CD, 1) IN (3, 4, 5, 6) AND LEFT(ENTITY_CD, 11) = '00000000000'
;

--Interested in ratio of students that go from Pre-K to K.
SELECT ENTITY_CD, ENTITY_NAME, PK, Khalf, KFULL, CAST(ROUND((KHALF+KFULL)/PK, 4) AS decimal(10,4)) AS 'K-PK ratio'
FROM [BEDS Day Enrollment]
WHERE PK>0 AND KHALF+KFULL>0
ORDER BY [K-PK ratio]
--KIRYAS JOEL VILLAGE UNION FREE SCHOOL DISTRICT, for example, must only be for Pre-K students.

SELECT * FROM [Demographic Factors]
WHERE ENTITY_CD=441202020000;

--Public Schools that have the highest Average percent homeless students
SELECT dg.ENTITY_NAME, AVG(PER_HOMELESS) AS AvgPerHomeless
	FROM [Demographic Factors] dg
		JOIN [Institution Grouping] ig ON ig.ENTITY_CD = dg.ENTITY_CD
	WHERE PER_SWD>90
		AND ig.GROUP_NAME = 'Public School'
	GROUP BY dg.YEAR, dg.ENTITY_NAME, PER_HOMELESS
	ORDER BY AvgPerHomeless DESC, ENTITY_NAME;

--I was seeing duplicate data..  Each row had a duplicate.
--Must have been a mistake with exporting the table from Access
--Here I will delete the duplicate rows:

WITH cte AS
(
SELECT [INSTITUTION_ID]
      ,[GROUP_CODE]
      ,[GROUP_NAME]
      ,[ENTITY_CD]
      ,[ENTITY_NAME]
	  ,row_number() OVER(PARTITION BY INSTITUTION_ID, GROUP_CODE, GROUP_NAME, ENTITY_Name ORDER BY ENTITY_CD) as row_num
  FROM [NYSED 2021 DB].[dbo].[Institution Grouping]
 )
 DELETE FROM cte
 WHERE row_num = 2


	-- K-12 Totals by County.  Could Filter out NYC Public Schools County.
SELECT bd.ENTITY_NAME, bd.Year, K12 as 'K-12 Total'
FROM [BEDS Day Enrollment] bd
JOIN [Institution Grouping] ig
	ON bd.ENTITY_CD = ig.ENTITY_CD
WHERE bd.YEAR = 2021 AND ig.GROUP_CODE = 2
ORDER BY K12 DESC;


--Top 10 most populated Counties and their demographic breakdown
SELECT TOP 10
	bd.ENTITY_NAME,
	bd.Year, K12 as 'K-12 Total',
	df.PER_BLACK,
	df.PER_HISP,
	df.PER_ASIAN,
	df.PER_Multi,
	df.PER_AM_IND,
	df.PER_WHITE

FROM [BEDS Day Enrollment] bd
	JOIN [Institution Grouping] ig
		ON bd.ENTITY_CD = ig.ENTITY_CD
	JOIN [Demographic Factors] df
		ON df.ENTITY_CD = bd.ENTITY_CD AND df.Year = bd.YEAR
WHERE bd.YEAR = 2021 AND
		ig.GROUP_CODE = 2 AND
		bd.ENTITY_NAME <> 'NYC Public Schools County'
ORDER BY K12 DESC;


--Top 10 most populated Districts and their demographic breakdown
SELECT TOP 10

	bd.ENTITY_NAME,
	bd.Year, K12 as 'K-12 Total',
	df.PER_BLACK,
	df.PER_HISP,
	df.PER_ASIAN,
	df.PER_Multi,
	df.PER_AM_IND,
	df.PER_WHITE

FROM [BEDS Day Enrollment] bd
	JOIN [Institution Grouping] ig
		ON bd.ENTITY_CD = ig.ENTITY_CD
	JOIN [Demographic Factors] df
		ON df.ENTITY_CD = bd.ENTITY_CD AND df.Year = bd.YEAR
WHERE bd.YEAR = 2021 AND
		ig.GROUP_CODE = 5
ORDER BY K12 DESC;

--Same as above, except let's non-NYC districts
SELECT TOP 10
	bd.ENTITY_CD,
	bd.ENTITY_NAME,
	bd.Year, K12 as 'K-12 Total',
	df.PER_BLACK,
	df.PER_HISP,
	df.PER_ASIAN,
	df.PER_Multi,
	df.PER_AM_IND,
	df.PER_WHITE

FROM [BEDS Day Enrollment] bd
	JOIN [Institution Grouping] ig
		ON bd.ENTITY_CD = ig.ENTITY_CD
	JOIN [Demographic Factors] df
		ON df.ENTITY_CD = bd.ENTITY_CD AND df.Year = bd.YEAR
WHERE bd.YEAR = 2021 AND
		ig.GROUP_CODE = 5 AND
		LEFT(bd.ENTITY_CD,2) NOT IN (30,31,32,33,34,35)
ORDER BY K12 DESC;

--Looking at the Top 10 Counties by Number of students again,
--looking at Percent of students who are economically disadvantaged
SELECT TOP 10
	bd.ENTITY_NAME,
	bd.Year, K12 as 'K-12 Total',
	df.PER_ECDIS

FROM [BEDS Day Enrollment] bd
	JOIN [Institution Grouping] ig
		ON bd.ENTITY_CD = ig.ENTITY_CD
	JOIN [Demographic Factors] df
		ON df.ENTITY_CD = bd.ENTITY_CD AND df.Year = bd.YEAR
WHERE bd.YEAR = 2021 AND
		ig.GROUP_CODE = 2 AND
		bd.ENTITY_NAME <> 'NYC Public Schools County'
ORDER BY K12 DESC;


--Check to see if every district is in every Year:
SELECT Year, COUNT(*) AS 'Number of Counties'
FROM [BEDS Day Enrollment]
WHERE ENTITY_CD IN (
		SELECT ENTITY_CD
		FROM [Institution Grouping]
		WHERE GROUP_CODE = 5
		)
GROUP BY YEAR
ORDER BY YEAR
;  

--  Which District did not report enrollment data in 2021?

SELECT ENTITY_NAME
FROM [BEDS Day Enrollment]
WHERE ENTITY_CD IN (
		SELECT ENTITY_CD
		FROM [Institution Grouping]
		WHERE GROUP_CODE = 5
		)
AND Year = 2020
AND ENTITY_CD NOT IN (
			SELECT ENTITY_CD
			FROM [BEDS Day Enrollment]
			WHERE YEAR = 2021
			)
--Berkshire Union Free School District did not report enrollment data in 2021



--Trying to find list of districts that didn't report all 3 years of enrollment
SELECT ENTITY_NAME AS 'District'
FROM [BEDS Day Enrollment]
	WHERE (  
		Year = 2019
		AND ENTITY_CD IN (
			SELECT ENTITY_CD
			FROM [Institution Grouping]
				WHERE GROUP_CODE = 5  --District Code
			)
		AND ENTITY_CD NOT IN (
			SELECT ENTITY_CD
			FROM [BEDS Day Enrollment]
				WHERE Year = 2020
			)
		)
	OR         --Compare 2020 to 2019
		(
		ENTITY_CD IN (
			SELECT ENTITY_CD
			FROM [Institution Grouping]
				WHERE GROUP_CODE = 5
			)
	AND ENTITY_CD NOT IN (
		SELECT ENTITY_CD
		FROM [BEDS Day Enrollment]
			WHERE Year = 2019
			)
	AND Year = 2020
	)
	--I am realizing how inefficient this code is, and I have another idea.

--This is much better code!
--List of Districts that didn't report all 3 years
SELECT ENTITY_NAME, COUNT(*)
FROM [BEDS Day Enrollment]
	WHERE ENTITY_CD in (
			SELECT ENTITY_CD
			FROM [Institution Grouping]
				WHERE GROUP_CODE = 5
			)
GROUP BY ENTITY_NAME
HAVING COUNT(*) < 3


--Percent enrollment change by District 2019 to 2020

WITH t19 AS (
	SELECT ENTITY_CD, ENTITY_NAME, YEAR, K12
	FROM [BEDS Day Enrollment]
		WHERE YEAR = 2019
			AND ENTITY_CD IN (
				SELECT ENTITY_CD
				FROM [Institution Grouping]
					WHERE GROUP_CODE = 5
				)
	),
t20 AS (
	SELECT ENTITY_CD, ENTITY_NAME, YEAR, K12
	FROM [BEDS Day Enrollment]
		WHERE YEAR = 2020
			AND ENTITY_CD IN (
				SELECT ENTITY_CD
				FROM [Institution Grouping]
					WHERE GROUP_CODE = 5
				)
	),
t21 AS (
	SELECT ENTITY_CD, ENTITY_NAME, YEAR, K12
	FROM [BEDS Day Enrollment]
		WHERE YEAR = 2021
			AND ENTITY_CD IN (
				SELECT ENTITY_CD
				FROM [Institution Grouping]
					WHERE GROUP_CODE = 5
				)
	)
SELECT
	t19.ENTITY_NAME AS "District",
	t19.K12 AS "2019 Enrollment",
	t20.K12 AS "2020 Enrollment",
	FORMAT((t20.K12-t19.K12)/t19.K12, 'p2') AS "Enrollment between 19 & 20"
FROM t19, t20
WHERE t19.ENTITY_CD = t20.ENTITY_CD
ORDER BY (t20.K12-t19.K12)/t19.K12 DESC;

--SAME AS ABOVE but comparing 2020 to 2021

WITH t19 AS (
	SELECT ENTITY_CD, ENTITY_NAME, YEAR, K12
	FROM [BEDS Day Enrollment]
		WHERE YEAR = 2019
			AND ENTITY_CD IN (
				SELECT ENTITY_CD
				FROM [Institution Grouping]
					WHERE GROUP_CODE = 5
				)
	),
t20 AS (
	SELECT ENTITY_CD, ENTITY_NAME, YEAR, K12
	FROM [BEDS Day Enrollment]
		WHERE YEAR = 2020
			AND ENTITY_CD IN (
				SELECT ENTITY_CD
				FROM [Institution Grouping]
					WHERE GROUP_CODE = 5
				)
	),
t21 AS (
	SELECT ENTITY_CD, ENTITY_NAME, YEAR, K12
	FROM [BEDS Day Enrollment]
		WHERE YEAR = 2021
			AND ENTITY_CD IN (
				SELECT ENTITY_CD
				FROM [Institution Grouping]
					WHERE GROUP_CODE = 5
				)
	)
SELECT
	t20.ENTITY_NAME AS "District",
	t20.K12 AS "2020 Enrollment",
	t21.K12 AS "2021 Enrollment",
	FORMAT((t21.K12-t20.K12)/t20.K12, 'p2') AS "Enrollment between 20 & 21"
FROM t20, t21
WHERE t20.ENTITY_CD = t21.ENTITY_CD
ORDER BY (t21.K12-t20.K12)/t20.K12 DESC;


--Let's look at Tompkins County
SELECT *
FROM [Institution Grouping]
WHERE ENTITY_NAME LIKE 'TOMPKINS%';
--Tompkins County ENTITY_CD is 000061000000

--More Tompkins County data
SELECT bd.ENTITY_CD,
	bd.ENTITY_NAME,
	bd.Year, bd.K12,
	df.PER_FEMALE AS 'Percent Female',
	df.PER_MALE AS 'Percent Male',
	df.PER_SWD AS 'Percent Students with disabilities',
	df.PER_ECDIS AS 'Percent of economically disadvantaged students'
FROM [BEDS Day Enrollment] bd
JOIN [Demographic Factors] df
ON bd.ENTITY_CD = df.ENTITY_CD AND bd.YEAR = df.YEAR
WHERE LEFT(bd.ENTITY_CD, 2) = 61
AND RIGHT(bd.ENTITY_CD, 4) = 0000
ORDER BY ENTITY_CD, YEAR;

--Let's try to rank Tompkins County by different attributes

--Shows the rank of each school district by K-12 Enrollment in 2021
SELECT e.ENTITY_NAME, e.[K-12 Total], e.Rank
FROM (
	SELECT
		bd.ENTITY_NAME, bd.ENTITY_CD, 
		K12 as 'K-12 Total',
		rank() OVER (ORDER BY K12 DESC) AS 'Rank'

	FROM [BEDS Day Enrollment] bd
		JOIN [Institution Grouping] ig
			ON bd.ENTITY_CD = ig.ENTITY_CD
		JOIN [Demographic Factors] df
			ON df.ENTITY_CD = bd.ENTITY_CD AND df.Year = bd.YEAR
	WHERE bd.YEAR = 2021 AND
			ig.GROUP_CODE = 5 AND
			LEFT(bd.ENTITY_CD, 2) NOT IN (30,31,32,33,34,35)
) e
WHERE LEFT(ENTITY_CD,2) = 61;

--Table listing District in Tompkins County, K-12 Total in 2020, 2021, then the percent change

WITH cte AS (
	SELECT
		bd.ENTITY_NAME AS 'District',
		CAST(a.K12 AS float) AS 'enr_2020',
		CAST(b.K12 AS float) AS 'enr_2021',
		CAST((b.K12 - a.K12) AS float) AS 'diff'
	FROM [BEDS Day Enrollment] bd
	JOIN [BEDS Day Enrollment] a
		ON bd.ENTITY_CD = a.ENTITY_CD AND bd.YEAR = a.YEAR AND a.YEAR = 2020
	JOIN [BEDS Day Enrollment] b
		ON bd.ENTITY_CD = b.ENTITY_CD AND bd.YEAR = a.YEAR AND b.YEAR = 2021
	WHERE LEFT(bd.ENTITY_CD, 2) = 61 AND
		RIGHT (bd.ENTITY_CD, 4) = 0000
)
SELECT District, 
enr_2020,
enr_2021,
ROUND((diff/enr_2021)*100, 2) as percent_diff
FROM cte
ORDER BY percent_diff desc
--All districts in Tompkins County had a decrease in Enrollment from 2020 to 2021.



WITH cte AS (
	SELECT
		bd.ENTITY_NAME AS 'County',
		CAST(a.K12 AS float) AS 'k12_2020',
		CAST(b.K12 AS float) AS 'k12_2021'
	FROM [BEDS Day Enrollment] bd
	JOIN [BEDS Day Enrollment] a
		ON bd.ENTITY_CD = a.ENTITY_CD AND bd.YEAR = a.YEAR AND a.YEAR = 2020
	JOIN [BEDS Day Enrollment] b
		ON bd.ENTITY_CD = b.ENTITY_CD AND bd.YEAR = a.YEAR AND b.YEAR = 2021
	WHERE RIGHT(bd.ENTITY_NAME, 6) = 'County'
)
SELECT
	County,
	k12_2020,
	k12_2021,
	k12_2021 - k12_2020 AS enrollment_diff,
	ROUND(((k12_2021-k12_2020)/(k12_2020))*100, 2) as percent_diff,
	rank() OVER (ORDER BY k12_2021) AS K12_rank

FROM cte
ORDER by percent_diff desc

;

/*Hamilton County was the only county to see an increase in student enrollment
However, it is also has the lowest total enrollment
and only saw an enrollment difference of 20 students.
Between 2020 and 2021.  Let's look at 2019 - 2021.
*/

SELECT
	bd.ENTITY_NAME AS 'County',
	a.K12 AS '2019',
	b.K12 AS '2021',
	((b.K12-a.K12)) AS 'Enr_Change'
FROM [BEDS Day Enrollment] bd
JOIN [BEDS Day Enrollment] a
	ON bd.ENTITY_CD = a.ENTITY_CD AND bd.YEAR = a.YEAR AND a.YEAR = 2019
JOIN [BEDS Day Enrollment] b
	ON bd.ENTITY_CD = b.ENTITY_CD AND bd.YEAR = a.YEAR AND b.YEAR = 2021
WHERE RIGHT(bd.ENTITY_NAME, 6) = 'County' AND bd.ENTITY_NAME <> 'NYC Public Schools County'

--Every county saw a decrease.

--What is the average K12 enrollment by county
--And what is the difference between the county's enrollment and that average?
SELECT
	ENTITY_Name,
	(SELECT AVG(k12) FROM [BEDS Day Enrollment] WHERE RIGHT(ENTITY_NAME, 6) = 'County' AND ENTITY_NAME <> 'NYC Public Schools County')
		AS K12_avg,
	K12 - (SELECT AVG(k12) FROM [BEDS Day Enrollment] WHERE RIGHT(ENTITY_NAME, 6) = 'County' AND ENTITY_NAME <> 'NYC Public Schools County')
		AS K12_avg_diff
FROM [BEDS Day Enrollment]
WHERE RIGHT(ENTITY_NAME, 6) = 'County' AND ENTITY_NAME <> 'NYC Public Schools County' AND YEAR = 2021
ORDER BY K12_avg_diff


SELEC