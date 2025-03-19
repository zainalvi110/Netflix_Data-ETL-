
-- removing duplicates
select show_id ,count(*) from netflix_raw
group by show_id having count(*)>1

--title

select * from netflix_raw where CONCAT (upper (title) ,type) in(
select CONCAT (upper(title),type) from netflix_raw
group by  upper (title),type having count(*)>1)
order by title
-- removing duplicates
with cte as(
select *
,ROW_NUMBER() over(partition by title , type order by show_id)as rn
from netflix_raw)
select * from cte where rn=1

----table for listed in ,director,country,cast

select show_id,trim(value) as director into netflix_directors
from netflix_raw 
cross apply string_split(director,',')

select show_id,trim(value) as country into netflix_country
from netflix_raw 
cross apply string_split(country,',')

select show_id,trim(value) as cast into netflix_cast
from netflix_raw 
cross apply string_split(cast,',')

select show_id,trim(value) as listed_in into netflix_listed_in
from netflix_raw 
cross apply string_split(listed_in,',')

select * from netflix_listed_in
insert into netflix_country
select show_id,m.country from netflix_raw as nr
inner join(select director,country from netflix_country nc
inner join netflix_directors as nd on nc.show_id=nd.show_id
group by director,country) m on nr.director=m.director 
where nr.country is null 

select * from netflix_country where country is null

with cte as (
select * 
,ROW_NUMBER() over(partition by title , type order by show_id) as rn
from netflix_raw
)
select show_id,type,title,cast(date_added as date) as date_added,release_year
,rating,case when duration is null then rating else duration end as duration,description
into netflix
from cte 


select nd.director, count(distinct case when n.type='movie' then n.show_id end)as no_of_movies,
count(distinct case when n.type='Tv show' then n.show_id end)as no_of_tvshows
from netflix n 
inner join netflix_directors as nd on n.show_id=nd.show_id
group by nd.director
having  count(distinct n.type)>1
order by distinct_type desc

select nc.country ,count (distinct ng.show_id) as no_of_movies from netflix_listed_in  as ng
inner join netflix_country as nc on ng.show_id=nc.show_id
inner join netflix n on ng.show_id=nc.show_id
where ng.listed_in ='comedies' and n.type ='movies'
group by nc.country

--2 which country has highest number of comedy movies 
select  top 1 nc.country , COUNT(distinct ng.show_id ) as no_of_movies
from netflix_listed_in ng
inner join netflix_country nc on ng.show_id=nc.show_id
inner join netflix n on ng.show_id=nc.show_id
where ng.listed_in='Comedies' and n.type='Movie'
group by  nc.country
order by no_of_movies desc

--3 for each year (as per date added to netflix), which director has maximum number of movies released
with cte as (
select nd.director,YEAR(date_added) as date_year,count(n.show_id) as no_of_movies
from netflix n
inner join netflix_directors nd on n.show_id=nd.show_id
where type='Movie'
group by nd.director,YEAR(date_added)
)
, cte2 as (
select *
, ROW_NUMBER() over(partition by date_year order by no_of_movies desc, director) as rn
from cte
--order by date_year, no_of_movies desc
)
select * from cte2 where rn=1



--4 what is average duration of movies in each genre
select ng.listed_in , avg(cast(REPLACE(duration,' min','') AS int)) as avg_duration
from netflix n
inner join netflix_listed_in ng on n.show_id=ng.show_id
where type='Movie'
group by ng.listed_in

--5  find the list of directors who have created horror and comedy movies both.
-- display director names along with number of comedy and horror movies directed by them 
select nd.director
, count(distinct case when ng.listed_in='Comedies' then n.show_id end) as no_of_comedy 
, count(distinct case when ng.listed_in='Horror Movies' then n.show_id end) as no_of_horror
from netflix n
inner join netflix_listed_in ng on n.show_id=ng.show_id
inner join netflix_directors nd on n.show_id=nd.show_id
where type='Movie' and ng.listed_in in ('Comedies','Horror Movies')
group by nd.director
having COUNT(distinct ng.listed_in)=2;

select * from netflix_listed_in where show_id in 
(select show_id from netflix_directors where director='Steve Brill')
order by listed_in


