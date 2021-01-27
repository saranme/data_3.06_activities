-- ACTIVITIES
Use bank;
/*
3.06 Activity 1
Keep working on the bank database.

Use a CTE to display the first account opened by a district.
*/
WITH min_date_dist AS (SELECT district_id, MIN(date) min_date
						FROM account
						GROUP BY 1
						ORDER BY 1
                        )
SELECT account_id, district_id, date
FROM account
WHERE EXISTS (SELECT * 
			FROM min_date_dist 
			WHERE min_date_dist.district_id = account.district_id
            AND min_date_dist.min_date = account.date
            )
				
ORDER BY 2;

/*
3.06 Activity 2
In order to spot possible fraud, 
we want to create a view last_week_withdrawals with total withdrawals 
by client in the last week.
*/
WITH last_week AS (SELECT * 
					FROM trans
					WHERE date BETWEEN (SELECT MAX(date) -7 FROM trans)
					AND (SELECT MAX(date) FROM trans) AND type = 'VYDAJ'
                    ) 
SELECT account_id, COUNT(operation) n_withdrawals
FROM last_week
GROUP BY 1
ORDER BY 2 DESC;

/*
3.06 Activity 3
The table client has a field birth_number that encapsulates client birthday and sex. 
The number is in the form YYMMDD for men, and in the form YYMM+50DD for women, 
where YYMMDD is the date of birth. 
Create a view client_demographics with client_id, birth_date and sex fields. 
Use that view and a CTE to find the number of loans by status and sex.
*/
DROP VIEW IF EXISTS client_demographics;
CREATE VIEW client_demographics AS
SELECT client_id, 
		CASE WHEN SUBSTRING(birth_number,3,2) > 50 
		THEN CONCAT(SUBSTRING(birth_number,1,2),SUBSTRING(birth_number,3,2) -50,SUBSTRING(birth_number,5,2)) 
		ELSE birth_number END AS correct_birth,
		CASE WHEN SUBSTRING(birth_number,3,2) > 50 THEN 'female' ELSE 'male' END AS sex
FROM client;

-- Use that view and a CTE to find the number of loans by status and sex.
WITH client_info AS (SELECT cd.client_id, cd.correct_birth, cd.sex, l.loan_id, l.account_id, l.status
					FROM loan l
					JOIN account a
					ON l.account_id = a.account_id
					JOIN disp d
					ON a.account_id = d.account_id
					JOIN client_demographics cd
					ON d.client_id = cd.client_id
                    )
SELECT COUNT(loan_id) n_loans, status, sex
FROM client_info
GROUP BY 2,3;

/*
3.06 Activity 4
Select loans greater than the average in their district.
*/
DROP VIEW IF EXISTS avg_loans_dist;
CREATE VIEW avg_loans_dist AS
WITH dist_loans AS (SELECT l.loan_id, l.amount, d.A1 dist_id, d.A2 dist_name
					FROM loan l
					JOIN account a
					ON a.account_id = l.account_id
					JOIN district d
					ON a.district_id = d.A1
                    )
SELECT AVG(amount) avg_amount, dist_id, dist_name
FROM dist_loans
GROUP BY 2,3
ORDER BY 2;

DROP VIEW IF EXISTS dist_loans;
CREATE VIEW dist_loans AS (SELECT l.loan_id, l.amount, d.A1 dist_id, d.A2 dist_name
					FROM loan l
					JOIN account a
					ON a.account_id = l.account_id
					JOIN district d
					ON a.district_id = d.A1
                    );

SELECT *
FROM (SELECT dl.loan_id, dl.amount, dl.dist_id, dl.dist_name, ald.avg_amount
	FROM dist_loans dl
	JOIN avg_loans_dist ald
	ON ald.dist_id = dl.dist_id
	ORDER BY dist_id
	) AS avg_loans_dist_complete
WHERE amount >= avg_amount
ORDER BY 1

