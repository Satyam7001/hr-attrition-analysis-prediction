CREATE TABLE hr_raw(
	employee_id   TEXT,
	employee_name TEXT,
	location 	  TEXT,
	department 	TEXT,
	job_level TEXT,
	gender TEXT,
	age TEXT,
	education TEXT,
	marital_status TEXT,
	join_date TEXT,
	exit_date TEXT,
	attrited TEXT,
	overtime TEXT,
	satisfaction_score TEXT,
	commute_km TEXT,
	salary_hike_pct TEXT,
	performance_rating TEXT,
	monthly_salary TEXT
)
select * from hr_raw;
select count(*) from hr_raw;
select * from hr_raw limit(10);

-- checking for duplicate rows --
SELECT COUNT(*) AS total_rows,
	COUNT(DISTINCT(employee_id,employee_name,location,department,job_level,gender,age,education,marital_status,join_date,exit_date,attrited,overtime,satisfaction_score,commute_km,salary_hike_pct,performance_rating,monthly_salary)) AS DISTINCT_ROWS
	FROM hr_raw;

-- checking for null rows --

SELECT
	COUNT(*) FILTER(WHERE location IS NULL OR location = '') AS missing_location,
	COUNT(*) FILTER(WHERE age IS NULL OR age ='') AS missing_age,
	COUNT(*) FILTER(WHERE education IS NULL OR education ='') AS missing_education,
	COUNT(*) FILTER(WHERE join_date IS NULL OR join_date ='') AS missing_join_date,
	COUNT(*) FILTER(WHERE exit_date IS NULL OR exit_date ='') AS missing_exit_date,
	COUNT(*) FILTER(WHERE satisfaction_score IS NULL OR satisfaction_score ='') AS missing_satisfaction_score,
	COUNT(*) FILTER(WHERE commute_km IS NULL OR commute_km ='') AS missing_commute_km,
	COUNT(*) FILTER(WHERE salary_hike_pct IS NULL OR salary_hike_pct ='') AS missing_salary_hike_pct,
	COUNT(*) FILTER(WHERE monthly_salary IS NULL OR monthly_salary ='') AS missing_monthly_salary
FROM hr_raw;

-- checking for null rows --

CREATE TABLE hr_dedup AS 
SELECT DISTINCT * FROM hr_raw;

SELECT COUNT(*) FROM hr_dedup;

-- Confirming the exit_date theory --

SELECT attrited, COUNT (*) AS TOTAL,
	COUNT(*) FILTER(WHERE exit_date IS NULL OR exit_date ='') AS missing_exit_date
FROM hr_dedup
GROUP BY attrited; 

-- checking LOCATIONS --

SELECT location, COUNT(*) 
FROM hr_dedup
GROUP BY location
ORDER BY COUNT(*) DESC;

-- Standardising location --

CREATE TABLE hr_clean AS
SELECT 
	employee_id,
	employee_name,
	CASE
		WHEN TRIM(location) IN('Bangalore', 'BANGALORE', 'Banglore', 'Bengaluru', 'bangalore') THEN 'Bangalore'
		WHEN TRIM(location) IN('MUMBAI','Mumbai','mumbai') THEN 'Mumbai'
		WHEN TRIM(location) IN('Pune','PUNE','pune') THEN 'Pune'
		WHEN TRIM(location) IN('delhi','New Delhi', 'DELHI','Delhi') THEN 'Delhi'
		WHEN TRIM(location) IN('Hyderbad','HYDERABAD','hyderabad','Hyderabad') THEN 'Hyderabad'
		WHEN TRIM(location) IN('Chennai','chennai','CHENNAI') THEN 'Chennai'
		ELSE TRIM(location)
	END AS location,
	department,
	job_level,
	gender,
	age,
	education,
	marital_status,
	join_date,
	exit_date,
	attrited,
	overtime,
	satisfaction_score,
	commute_km,
	salary_hike_pct,
	performance_rating,
	monthly_salary
FROM hr_dedup;

SELECT location, COUNT(*) FROM hr_clean
GROUP BY location
ORDER BY COUNT(*) DESC;


-- Calculating attrition rate by location --

SELECT location, 
	COUNT(*) AS total_employees,
	COUNT(*) FILTER(WHERE attrited = 'Yes') AS attrited_count,
	ROUND(
		COUNT(*) FILTER(WHERE attrited ='Yes'):: NUMERIC / COUNT(*) * 100, 2
	) AS attrition_rate_pct
FROM hr_clean
GROUP BY location
ORDER BY attrition_rate_pct DESC;



-- Fixing age values -- 

SELECT age, COUNT(*)
FROM hr_clean
GROUP BY age
ORDER BY age::NUMERIC;

-- 17 AND 99 ARE NOT ALLOWED, MEANS JOB IN INDIA ONLY ABOVE 21 AND TILL 80. THESE ARE OUTLIERS, REMOVING THEM --

ALTER TABLE hr_clean ADD COLUMN age_clean INT;
UPDATE hr_clean 
SET age_clean = CASE
				WHEN age='' OR age IS NULL THEN NULL
				WHEN age::NUMERIC <= 18 OR age::NUMERIC >=80 THEN NULL
				ELSE ROUND(age::NUMERIC)::INT
END;				

SELECT age_clean, COUNT(*)
FROM hr_clean
GROUP BY age_clean
ORDER BY age_clean;

--confirming the three groups age 17,99,NULL--

SELECT 
	COUNT(*) FILTER(WHERE age = '' OR age IS NULL) AS truly_blank,
	COUNT(*) FILTER(WHERE age::NUMERIC = 17) AS age_17,
	COUNT(*) FILTER(WHERE age::NUMERIC = 99) AS age_99
FROM hr_clean;


-- cleaning department and gender --
SELECT department, COUNT(*)
FROM hr_clean
GROUP BY department
ORDER BY COUNT(*) DESC;

SELECT gender, COUNT(*) 
FROM hr_clean
GROUP BY gender
ORDER BY COUNT(*) DESC;

-- CLEANING DEPARTEMNT --

ALTER TABLE hr_clean ADD COLUMN department_clean TEXT;
UPDATE hr_clean
SET department_clean = CASE
	WHEN TRIM(REGEXP_REPLACE(department, '\s+' , '' , 'g')) ILIKE 'engineering' THEN 'Engineering'
	WHEN TRIM(REGEXP_REPLACE(department, '\s+', '', 'g')) ILIKE 'sales' THEN 'Sales'
	WHEN TRIM(REGEXP_REPLACE(department, '\s+', '', 'g')) ILIKE 'marketing' THEN 'Marketing'
	WHEN TRIM(REGEXP_REPLACE(department, '\s+', '', 'g')) ILIKE 'customer support' THEN 'Customer Support'
	WHEN TRIM(REGEXP_REPLACE(department, '\s+', '', 'g')) ILIKE 'hr' THEN 'Hr'
	WHEN TRIM(REGEXP_REPLACE(department, '\s+', '', 'g')) ILIKE 'finance' THEN 'Finance'
	WHEN TRIM(REGEXP_REPLACE(department, '\s+', '', 'g')) ILIKE 'operations' THEN 'Operations'
	WHEN TRIM(REGEXP_REPLACE(department, '\s+', '', 'g')) ILIKE 'sales' THEN 'Sales'
	ELSE TRIM(department)
END;
SELECT department_clean, COUNT(*) FROM hr_clean GROUP BY department_clean ORDER BY COUNT(*) DESC;
	
-- CLEANING GENDER --

ALTER TABLE hr_clean ADD COLUMN gender_clean TEXT;
UPDATE hr_clean 
SET gender_clean = CASE
	WHEN TRIM(gender) IN('f','F','Female') THEN 'F'
	WHEN TRIM(gender) IN('m','M','Male') THEN 'M'
	ELSE NULL
END;

SELECT gender_clean, COUNT(*) FROM hr_clean GROUP BY gender_clean ORDER BY COUNT(*) DESC;


-- CUSTOMER SUPPORT 2 TIMS CAME WHATS DIFFERENCE BETWEEN THEM? -- 

SELECT department, LENGTH(department), COUNT(*)
FROM hr_clean
WHERE department ILIKE '%customer%support%'
GROUP BY department, LENGTH(department);


UPDATE hr_clean
SET department_clean = CASE
    WHEN LOWER(REGEXP_REPLACE(TRIM(department), '\s+', ' ', 'g')) = 'engineering' THEN 'Engineering'
    WHEN LOWER(REGEXP_REPLACE(TRIM(department), '\s+', ' ', 'g')) = 'sales' THEN 'Sales'
    WHEN LOWER(REGEXP_REPLACE(TRIM(department), '\s+', ' ', 'g')) = 'marketing' THEN 'Marketing'
    WHEN LOWER(REGEXP_REPLACE(TRIM(department), '\s+', ' ', 'g')) = 'customer support' THEN 'Customer Support'
    WHEN LOWER(REGEXP_REPLACE(TRIM(department), '\s+', ' ', 'g')) = 'hr' THEN 'HR'
    WHEN LOWER(REGEXP_REPLACE(TRIM(department), '\s+', ' ', 'g')) = 'finance' THEN 'Finance'
    WHEN LOWER(REGEXP_REPLACE(TRIM(department), '\s+', ' ', 'g')) = 'operations' THEN 'Operations'
    ELSE TRIM(department)
END;

SELECT department_clean, COUNT(*) FROM hr_clean GROUP BY department_clean ORDER BY COUNT(*) DESC;


-- Testing overtime --

SELECT overtime,
	COUNT(*) AS total_employee,
	COUNT(*) FILTER(WHERE attrited = 'Yes') AS attrited_count,
	ROUND(
		COUNT(*) FILTER(WHERE attrited = 'Yes')::NUMERIC/COUNT(*)*100,2	
	) AS attrition_rate_pct
FROM hr_clean
GROUP BY overtime;

-- Testing overtime BANGALORE ONLY --

SELECT overtime,
	COUNT(*) AS total_employee,
	COUNT(*) FILTER(WHERE attrited = 'Yes') AS attritd_count,
	ROUND(
	COUNT (*) FILTER(WHERE attrited = 'Yes')::NUMERIC/COUNT(*)*100,2
	) AS attrition_rate_pct
FROM hr_clean
WHERE location = 'Bangalore'
GROUP BY overtime;

-- Testing satisfaction_score BANGALORE ONLY --

SELECT 
    satisfaction_score,
    COUNT(*) AS total_employees,
    COUNT(*) FILTER (WHERE attrited = 'Yes') AS attrited_count,
    ROUND(
        COUNT(*) FILTER (WHERE attrited = 'Yes')::NUMERIC / COUNT(*) * 100, 
        2
    ) AS attrition_rate_pct
FROM hr_clean
WHERE location = 'Bangalore'
GROUP BY satisfaction_score
ORDER BY satisfaction_score;

-- Testing commute_km BANGALORE ONLY --

SELECT 
    CASE WHEN commute_km::NUMERIC > 25 THEN 'Long commute (>25km)' ELSE 'Short commute (<=25km)' END AS commute_group,
    COUNT(*) AS total_employees,
    COUNT(*) FILTER (WHERE attrited = 'Yes') AS attrited_count,
    ROUND(
        COUNT(*) FILTER (WHERE attrited = 'Yes')::NUMERIC / COUNT(*) * 100, 
        2
    ) AS attrition_rate_pct
FROM hr_clean
WHERE location = 'Bangalore' AND commute_km IS NOT NULL AND commute_km != ''
GROUP BY commute_group;

-- Testing salary_hike BANGALORE ONLY --

SELECT 
    CASE WHEN salary_hike_pct::NUMERIC < 6 THEN 'Low hike (<6%)' ELSE 'Normal/High hike (>=6%)' END AS hike_group,
    COUNT(*) AS total_employees,
    COUNT(*) FILTER (WHERE attrited = 'Yes') AS attrited_count,
    ROUND(
        COUNT(*) FILTER (WHERE attrited = 'Yes')::NUMERIC / COUNT(*) * 100, 
        2
    ) AS attrition_rate_pct
FROM hr_clean
WHERE location = 'Bangalore' AND salary_hike_pct IS NOT NULL AND salary_hike_pct != ''
GROUP BY hike_group;


--DATE FIXING --

ALTER TABLE hr_clean ADD COLUMN join_date_clean DATE;

UPDATE hr_clean
SET join_date_clean = CASE
    WHEN join_date IS NULL OR join_date = '' THEN NULL

    -- ISO with time: 2020-03-15 00:00:00
    WHEN join_date ~ '^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$' 
        THEN TO_DATE(LEFT(join_date, 10), 'YYYY-MM-DD')

    -- ISO date: 2020-03-15 (unambiguous, year first)
    WHEN join_date ~ '^\d{4}-\d{2}-\d{2}$' 
        THEN TO_DATE(join_date, 'YYYY-MM-DD')

    -- dash, DD-MM-YYYY or MM-DD-YYYY
    WHEN join_date ~ '^\d{2}-\d{2}-\d{4}$' THEN
        CASE
            WHEN SPLIT_PART(join_date, '-', 1)::INT > 12 THEN TO_DATE(join_date, 'DD-MM-YYYY')
            WHEN SPLIT_PART(join_date, '-', 2)::INT > 12 THEN TO_DATE(join_date, 'MM-DD-YYYY')
            ELSE TO_DATE(join_date, 'DD-MM-YYYY')  -- ambiguous -> default day-first
        END

    -- slash, MM/DD/YYYY or DD/MM/YYYY
    WHEN join_date ~ '^\d{2}/\d{2}/\d{4}$' THEN
        CASE
            WHEN SPLIT_PART(join_date, '/', 1)::INT > 12 THEN TO_DATE(join_date, 'DD/MM/YYYY')
            WHEN SPLIT_PART(join_date, '/', 2)::INT > 12 THEN TO_DATE(join_date, 'MM/DD/YYYY')
            ELSE TO_DATE(join_date, 'MM/DD/YYYY')  -- ambiguous -> default month-first (US slash convention)
        END

    ELSE NULL
END;


--exit_date --

ALTER TABLE hr_clean ADD COLUMN exit_date_clean DATE;

UPDATE hr_clean
SET exit_date_clean = CASE
    WHEN exit_date IS NULL OR exit_date = '' THEN NULL
    WHEN exit_date ~ '^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$' 
        THEN TO_DATE(LEFT(exit_date, 10), 'YYYY-MM-DD')
    WHEN exit_date ~ '^\d{4}-\d{2}-\d{2}$' 
        THEN TO_DATE(exit_date, 'YYYY-MM-DD')
    WHEN exit_date ~ '^\d{2}-\d{2}-\d{4}$' THEN
        CASE
            WHEN SPLIT_PART(exit_date, '-', 1)::INT > 12 THEN TO_DATE(exit_date, 'DD-MM-YYYY')
            WHEN SPLIT_PART(exit_date, '-', 2)::INT > 12 THEN TO_DATE(exit_date, 'MM-DD-YYYY')
            ELSE TO_DATE(exit_date, 'DD-MM-YYYY')
        END
    WHEN exit_date ~ '^\d{2}/\d{2}/\d{4}$' THEN
        CASE
            WHEN SPLIT_PART(exit_date, '/', 1)::INT > 12 THEN TO_DATE(exit_date, 'DD/MM/YYYY')
            WHEN SPLIT_PART(exit_date, '/', 2)::INT > 12 THEN TO_DATE(exit_date, 'MM/DD/YYYY')
            ELSE TO_DATE(exit_date, 'MM/DD/YYYY')
        END
    ELSE NULL
END;
SELECT COUNT(*) FILTER (WHERE join_date_clean IS NULL) AS join_date_still_null,
       COUNT(*) FILTER (WHERE exit_date_clean IS NULL) AS exit_date_still_null
FROM hr_clean;


-- Testing tenure (do newer employees leave more than long-tenured ones?) BANGALORE ONLY--
SELECT 
    CASE 
        WHEN EXTRACT(YEAR FROM AGE('2025-07-31'::DATE, join_date_clean)) < 1 THEN 'Under 1 year'
        ELSE '1+ years'
    END AS tenure_group,
    COUNT(*) AS total_employees,
    COUNT(*) FILTER (WHERE attrited = 'Yes') AS attrited_count,
    ROUND(
        COUNT(*) FILTER (WHERE attrited = 'Yes')::NUMERIC / COUNT(*) * 100, 
        2
    ) AS attrition_rate_pct
FROM hr_clean
WHERE location = 'Bangalore'
GROUP BY tenure_group;

