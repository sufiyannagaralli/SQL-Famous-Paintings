-- Using database painting
use painting;

select * from artist;
select * from canvas_size;
select * from image_link;
select * from museum;
select * from museum_hours;
select * from product_size;
select * from subject;
select * from work;
select * from product_size1;


-- Checking the datatype of the column size_id.
SELECT data_type
FROM information_schema.columns
WHERE table_name = 'product_size1'
AND column_name = 'size_id';

-- Fetch all the paintings which are not displayed in any museums?
-- In Total we got 10223 rows as output which are not displayed in any museum.

select * from work where museum_id is null;


-- Are there museums without any paintings?
/* For this task, we utilized a correlated subquery to identify museum IDs that do not match 
between two tables, So there were no museums without painting*/

select * from museum m
where not exists (select 1 from work w
where w.museum_id=m.museum_id)


-- How many paintings have an asking price of more than their regular price? 
-- There are no paintings whose asking price is more then regular price.

select * from product_size
where sale_price > regular_price;


-- Identify the paintings whose asking price is less than 50% of its regular price?
-- There are a total 58 painting who's asking price is less than 50% of its regular price.

select * 
from product_size
where sale_price < (regular_price*0.5);


-- Which canva size costs the most?
-- using window function, subquery, and joins.
-- 48" x 96"(122 cm x 244 cm) canva size cost the most 1115/- .


SELECT cs.label AS canva, ps.sale_price
FROM (
    SELECT *, 
           Dense_RANK() OVER (ORDER BY sale_price DESC) AS rnk 
    FROM product_size1
) ps
JOIN canvas_size cs ON cs.size_id = ps.size_id
WHERE ps.rnk = 1

-- using joins
-- 48" x 96"(122 cm x 244 cm) canva size cost the most 1115/- .

SELECT c.label AS canvas, p.sale_price 
FROM canvas_size c
JOIN product_size1 p ON c.size_id = p.size_id
WHERE p.sale_price = (SELECT MAX(sale_price) FROM product_size1);

	
-- Identify the museums with invalid city information in the given dataset
-- There are a total of 6 invalid city entries in the given dataset.

select * from museum 
where  city like '[0-9]%'


-- Fetch the top 10 most famous painting subject
-- For this we used sub-query, window function, and joins
-- We utilized window functions to retrieve the top 10 outputs in descending order.
-- We utilized joins to retrieve data from two tables.

select * 
from (
	select s.subject,count(1) as no_of_paintings
	,rank() over(order by count(1) desc) as ranking
	from work w
	join subject s on s.work_id=w.work_id
	group by s.subject ) x
	where ranking <= 10;

-- Identify the museums which are open on both Sunday and Monday. Display museum name, city?
-- There are total 28 museums which are open on both Sunday as well as Monday

-- using sub-query and inner join:
select distinct m.name as museum_name, m.city, m.state,m.country
from museum_hours mh 
join museum m on m.museum_id=mh.museum_id
where day='Sunday'
and exists (select 1 from museum_hours mh2 
			where mh2.museum_id=mh.museum_id 
			and mh2.day='Monday');

-- Using self join and inner join:
SELECT m.[name], m.city
FROM museum_hours mh1
JOIN museum_hours mh2 ON mh1.museum_id = mh2.museum_id
JOIN museum m ON mh1.museum_id = m.museum_id
WHERE mh1.day = 'Sunday' AND mh2.day = 'Monday';


-- How many museums are open every single day?
-- The total number of museums open every single day is 18.

select count(*) as 'open on every single day'
from (select museum_id, count(1) AS count_of_entries
		 from museum_hours
		 group by museum_id
		 having count(1) = 7) x;

/* Which are the top 5 most popular museum? 
(Popularity is defined based on most no of paintings in a museum)?*/

/* The Metropolitan Museum of Art, Rijksmuseum, National Gallery, National Gallery of Art,
The Barnes Foundation are top 5 most popular museum. */

select m.name as museum, m.city,m.country,x.no_of_painintgs
from (	select m.museum_id, count(1) as no_of_painintgs
		, rank() over(order by count(1) desc) as rnk
		from work w
		join museum m on m.museum_id=w.museum_id
		group by m.museum_id) x
join museum m on m.museum_id=x.museum_id
where x.rnk<=5;


/*  Who are the top 5 most popular artist? 
(Popularity is defined based on most no of paintings done by an artist)?*/

/* Pierre-Auguste Renoir, Claude Monet, Albert Marquet, Maurice Utrillo, Vincent Van Gogh 
are the top 5 most popular artist */

select a.full_name as artist, a.nationality,x.no_of_painintgs
from (	select a.artist_id, count(1) as no_of_painintgs
		, rank() over(order by count(1) desc) as rnk
		from work w
		join artist a on a.artist_id=w.artist_id
		group by a.artist_id) x
join artist a on a.artist_id=x.artist_id
where x.rnk<=5;

--  Display the 3 least popular canva sizes

SELECT label, ranking, no_of_paintings
FROM (
    SELECT cs.size_id, cs.label, COUNT(1) AS no_of_paintings,
           DENSE_RANK() OVER (ORDER BY COUNT(1)) AS ranking
    FROM work w
    JOIN product_size1 ps ON ps.work_id = w.work_id
    JOIN canvas_size cs ON cs.size_id = ps.size_id
    GROUP BY cs.size_id, cs.label
) x
WHERE x.ranking <= 3;


/* Which museum is open for the longest during a day. 
Dispay museum name, state and hours open and which day?*/

-- Musée du Louvre  museum is open for the longest during a day.

SELECT museum_name, city, day, open_time, close_time, duration
FROM (
    SELECT m.name AS museum_name, m.state AS city, day, [open], [close],
           CONVERT(TIME, [open]) AS open_time,
           CONVERT(TIME, [close]) AS close_time,
           DATEDIFF(MINUTE, CONVERT(TIME, [open]), CONVERT(TIME, [close])) AS duration,
           RANK() OVER (ORDER BY DATEDIFF(MINUTE, CONVERT(TIME, [open]), CONVERT(TIME, [close])) DESC) AS rnk
    FROM museum_hours mh
    JOIN museum m ON m.museum_id = mh.museum_id
) x
WHERE x.rnk = 1;

-- Which museum has the most no of most popular painting style?
-- The Metropolitan Museum of Art museum has the most no of most popular painting style.


with pop_style as 
		(select style
		,rank() over(order by count(1) desc) as rnk
		from work
		group by style),
	cte as
		(select w.museum_id,m.name as museum_name,ps.style, count(1) as no_of_paintings
		,rank() over(order by count(1) desc) as rnk
		from work w
		join museum m on m.museum_id=w.museum_id
		join pop_style ps on ps.style = w.style
		where w.museum_id is not null
		and ps.rnk=1
		group by w.museum_id, m.name,ps.style)
select museum_name,style,no_of_paintings
from cte 
where rnk=1;


-- Identify the artists whose paintings are displayed in multiple countries?
-- There are total 194 artists whose paintings are displayed in multiple countries


with cte as
	(select distinct a.full_name as artist
	--, w.name as painting, m.name as museum
	, m.country
	from work w
	join artist a on a.artist_id=w.artist_id
	join museum m on m.museum_id=w.museum_id)
select artist,count(1) as no_of_countries
from cte
group by artist
having count(1)>1
order by 2 desc;


/*Display the country and the city with most no of museums. Output 2 seperate columns 
to mention the city and country. If there are multiple value, seperate them with comma.? */

-- USA, Washington country and the city with most no of museums.


WITH cte_country AS (
    SELECT country, COUNT(1) AS country_count,
           RANK() OVER (ORDER BY COUNT(1) DESC) AS country_rnk
    FROM museum
    GROUP BY country
),
cte_city AS (
    SELECT city, COUNT(1) AS city_count,
           RANK() OVER (ORDER BY COUNT(1) DESC) AS city_rnk
    FROM museum
    GROUP BY city
)
SELECT
    (
        SELECT MAX(country)
        FROM cte_country
        WHERE country_rnk = 1
    ) AS most_common_country,
    (
        SELECT MAX(city)
        FROM cte_city
        WHERE city_rnk = 1
    ) AS most_common_city;

/*Identify the artist and the museum where the most expensive and least expensive painting is placed. 
Display the artist name, sale_price, painting name, museum name, museum city and canvas label*/
	
WITH cte AS (
    SELECT *,
           RANK() OVER (ORDER BY sale_price DESC) AS rnk,
           RANK() OVER (ORDER BY sale_price) AS rnk_asc
    FROM product_size1
)
SELECT w.name AS painting,
       cte.sale_price,
       a.full_name AS artist,
       m.name AS museum,
       m.city,
       cz.label AS canvas
FROM cte
JOIN work w ON w.work_id = cte.work_id
JOIN museum m ON m.museum_id = w.museum_id
JOIN artist a ON a.artist_id = w.artist_id
JOIN canvas_size cz ON CAST(cz.size_id AS NUMERIC) = CAST(cte.size_id AS NUMERIC)
WHERE rnk = 1 OR rnk_asc = 1;


-- Which country has the 5th highest no of paintings?
-- Spain country has the 5th highest no of paintings.


with cte as 
	(select m.country, count(1) as no_of_Paintings
	, rank() over(order by count(1) desc) as rnk
	from work w
	join museum m on m.museum_id=w.museum_id
	group by m.country)
select country, no_of_Paintings
from cte 
where rnk=5;

-- Which are the 3 most popular and 3 least popular painting styles?

-- Impressionism, Post-Impressionism, Realism are 3 most popular painting styles.
-- Avant-Garde, Art Nouveau, Japanese Art 3 least popular painting styles.


with cte as 
	(select style, count(1) as cnt
	, rank() over(order by count(1) desc) rnk
	, count(1) over() as no_of_records
	from work
	where style is not null
	group by style)
select style
, case when rnk <=3 then 'Most Popular' else 'Least Popular' end as remarks 
from cte
where rnk <=3
or rnk > no_of_records - 3;


/* Which artist has the most no of Portraits paintings outside USA?. Display artist name,
no of paintings and the artist nationality.*/

select full_name as artist_name, nationality, no_of_paintings
from (
	select a.full_name, a.nationality
	,count(1) as no_of_paintings
	,rank() over(order by count(1) desc) as rnk
	from work w
	join artist a on a.artist_id=w.artist_id
	join subject s on s.work_id=w.work_id
	join museum m on m.museum_id=w.museum_id
	where s.subject='Portraits'
	and m.country != 'USA'
	group by a.full_name, a.nationality) x
where rnk=1;	

