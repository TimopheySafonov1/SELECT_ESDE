-- Which staff members made the highest revenue for each store and deserve a bonus for the year 2017?
SELECT s.store_id, st.staff_id, st.first_name, st.last_name, SUM(amount) AS revenue
FROM store s
JOIN staff st ON st.store_id = s.store_id 
JOIN payment pay ON pay.staff_id = st.staff_id
WHERE EXTRACT(YEAR FROM pay.payment_date) = 2017
GROUP BY s.store_id, st.staff_id, st.first_name, st.last_name 
ORDER BY revenue DESC;


WITH payment_2017 AS (
    SELECT 
        staff_id,
        EXTRACT(YEAR FROM payment_date) AS payment_year,
        amount
    FROM 
        payment
    WHERE 
        EXTRACT(YEAR FROM payment_date) = 2017
)
SELECT 
    s.store_id, 
    st.staff_id, 
    st.first_name, 
    st.last_name, 
    SUM(p.amount) AS revenue
FROM 
    store s
JOIN 
    staff st ON st.store_id = s.store_id 
JOIN 
    payment_2017 p ON p.staff_id = st.staff_id
GROUP BY 
    s.store_id, 
    st.staff_id, 
    st.first_name, 
    st.last_name 
ORDER BY 
    revenue DESC;

-- Which five movies were rented more than the others, and what is the expected age of the audience for these movies?
SELECT f.film_id, f.title, f.rating,  COUNT(*) AS rental_count
FROM rental r
JOIN inventory i ON i.inventory_id = r.inventory_id
JOIN film f ON f.film_id = i.film_id
GROUP BY f.film_id, f.title, f.rating
ORDER BY rental_count DESC
LIMIT 5;


SELECT 
    f.film_id, 
    f.title, 
    f.rating,
    rental_count
FROM 
    film f
JOIN 
    (SELECT 
         i.film_id, 
         COUNT(r.rental_id) AS rental_count
     FROM 
         rental r
     JOIN 
         inventory i ON r.inventory_id = i.inventory_id
     GROUP BY 
         i.film_id
     ORDER BY 
         rental_count DESC
     LIMIT 5) AS top_rented 
ON f.film_id = top_rented.film_id
ORDER BY 
    top_rented.rental_count DESC;

-- Which actors/actresses didn't act for a longer period of time than the others?

-- actors who have not acted for a long time, counting the period from the last film until now
SELECT 
    a.actor_id,
    a.first_name,
    a.last_name,
    MAX(f.release_year) AS last_film_year,
    EXTRACT(YEAR FROM CURRENT_DATE) - MAX(f.release_year) AS years_inactive
FROM 
    actor a
JOIN 
    film_actor fa ON a.actor_id = fa.actor_id
JOIN 
    film f ON fa.film_id = f.film_id
GROUP BY 
    a.actor_id, a.first_name, a.last_name
ORDER BY 
    years_inactive DESC;

-- actors who have not acted for a long time, counting the period between two films
WITH FilmActors AS (
	SELECT a.actor_id, a.first_name, a.last_name, f.title, f.release_year
    FROM film f
    INNER JOIN film_actor fa ON f.film_id = fa.film_id
	INNER JOIN actor a ON fa.actor_id = a.actor_id
),

FilmActorsGap AS (
	SELECT actor_id, first_name, last_name, release_year,
		   LAG(release_year) OVER (PARTITION BY actor_id ORDER BY release_year) AS previous_release_year
	FROM FilmActors
),
ActorsGap AS (
	SELECT actor_id, first_name, last_name,
	       release_year - previous_release_year AS gap
	FROM FilmActorsGap
	where previous_release_year IS NOT NULL
),
MaxGap AS (
	SELECT actor_id, first_name, last_name,
	      MAX(gap) AS max_gap
	FROM ActorsGap
	GROUP BY actor_id, first_name, last_name
)
SELECT actor_id, first_name, last_name, max_gap
FROM MaxGap
ORDER BY max_gap DESC
