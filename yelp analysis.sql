use plott

exec sp_rename 'dbo.yelp_database$','yelp'

select* from yelp

---1. maximum rating by organization

select y.organization , y.rating
from yelp y
join( select organization, max(rating) maxx
	from yelp group by organization) y2
on y.organization=y2.organization 
and y.rating=y2.maxx

--2. find the best pizza hut in all state.

create index organizations on yelp(organization)

select organization,state, rating from(
			select organization,state,rating, ROW_NUMBER() over(partition by state order by rating desc) as rnk
			from yelp
			where organization='pizza hut') e
where e.rnk=1

--3. find the top 5  organization from top 5 state.

with state_ranking as(
	select state, avg_rating
	from(
		select state, avg(rating) as avg_rating, ROW_NUMBER() over(order by avg(rating) desc) rnk
		from yelp
		group by state )e
	where e.rnk<=5),

organization_rank as(
	select organization, state, rating, row_number() over (partition by state order by rating desc) rnk
	from yelp
	where state in(select state from state_ranking) ),

cte3 as(
	select state,organization,  rating,rnk
	from organization_rank
	where rnk<=5
)

select state,organization,  rating
from cte3 
where rnk=1
order by rating desc

--4. find the best and worst performing organization 

select* from yelp

with cte as(
	select organization, numberreview, avg(rating) as avg_rating
	from yelp
	where numberreview <>0
	group by organization, numberreview),

cte2 as(
	select organization,numberreview,avg_rating, ROW_NUMBER() over(order by avg_rating desc) as dsc_rnk
	from cte),

cte3 as(
	select  organization,numberreview,avg_rating ,ROW_NUMBER() over(order by avg_rating asc) as asc_rnk
	from cte)

select 'best performing' as performance,c2.organization,c2.avg_rating
from cte2 as c2
where dsc_rnk=1
union all
select 'least performing' as performance,c3.organization,c3.avg_rating
from cte3 as c3
where asc_rnk=1

--5. find the weightage of each category .

select category, sum(rating*numberreview)/  nullif(sum(numberreview),0) as overall_rating
from yelp
group by category 

--6. find the organization who get more rating on weekends as compare to normal weekdays.
 

with cte as(
	select organization, rating, cast(time_gmt as date) as weekend_rating
	from yelp
	where datepart(WEEKDAY,time_gmt) in(1,7) ),

cte2 as(
	select organization , rating, cast(time_gmt as date) as week_rating
	from yelp 
	where datepart( weekday, time_gmt) in(2,3,4,5,6))

select  distinct c.organization, c.rating,c2.rating
from cte c
join cte2 c2
on c.organization =c2.organization 
where c.rating>c2.rating 

--7. find the exact time of rating when an category face less rating .

with cte as(
	select category, rating , format(time_gmt,'hh:mm tt') as times,
			dense_rank() over(partition by category,format(time_gmt,'hh:mm tt') order by rating ) rnk 
	from yelp
	 )

select* from cte 
where rnk=1
and times is not null

--9. find the top organization in each category with respect to weightage overall rating.

select*from yelp

with cte as(
	select category, organization, sum(rating*numberreview)/nullif(sum(numberreview),0) as weightage 
	from yelp 
	group by category, organization)

select category, organization from(
	select category,organization, row_number() over(partition by category order by weightage desc) as rnk
	from cte ) e
where e.rnk=1


--10.find which state have more business registered in yelp

select* from yelp 

select top 1 state, count(organization) as cnt
from yelp 
group by state
order by cnt desc 

	






