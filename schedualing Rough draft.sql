--Show me todays's schedualing gap, High no-show providers, and avalable slots by department.

/*
Outputs:
Todays Schedual for all providers- 
	partitioned by dept
	then provider
	providers with high nopshow occurences (top 3)
	any empty time slots
*/
select*
from Provider p
join Appointment a
on p.providerid = a.providerid

-- All apt by provider
create or alter view dbo.Providerschedual
as
select
dense_rank()over (partition by a.providerid order by [ScheduledStart] desc) as prk,
p.ProviderID,
CONCAT(p.firstname,' ',LastName) as FullName,
d.DepartmentName,
a.ScheduledStart,
a.ScheduledEnd,
aps.StatusName
from Provider p
join Appointment a
on p.providerid = a.providerid 
join AppointmentStatus Aps
on a.AppointmentStatusID = aps.AppointmentStatusID
join Department d
on p.DepartmentID=d.DepartmentID;



--Today

select
dense_rank()over (partition by a.providerid order by [ScheduledStart] desc) as prk,
p.ProviderID,
CONCAT(p.firstname,' ',LastName) as FullName,
d.DepartmentName,
a.ScheduledStart,
a.ScheduledEnd,
aps.StatusName
from Provider p
join Appointment a
on p.providerid = a.providerid 
join AppointmentStatus Aps
on a.AppointmentStatusID = aps.AppointmentStatusID
join Department d
on p.DepartmentID=d.DepartmentID
where cast(a.ScheduledStart as date)= cast(getdate()as date);

--appointment gap
declare @targetdate date = cast(getdate() as date)
declare @Mingap int = 30

create or alter function dbo.fn_ProviderGap
(@targetdate  date, @Mingap int)
returns table 
as
return
with cte1 as(
select
dense_rank()over (partition by a.providerid order by [ScheduledStart] desc) as prk,
p.ProviderID,
CONCAT(p.firstname,' ',LastName) as FullName,
d.DepartmentName,
a.ScheduledStart,
a.ScheduledEnd,
aps.StatusName,
a.AppointmentID
from Provider p
join Appointment a
on p.providerid = a.providerid 
join AppointmentStatus Aps
on a.AppointmentStatusID = aps.AppointmentStatusID
join Department d
on p.DepartmentID = d.DepartmentID 
where cast(a.ScheduledEnd as date)= @targetdate), 


cte2 as(
select *
from (
	select *,
	row_number()over(partition by ProviderID, ScheduledStart,ScheduledEnd order by ScheduledEnd) as rn
	from cte1) start
	where rn=1),

cte3 as (
select
	b.prk,
	b.rn,
	b.ProviderID,
	b.FullName,
	b.DepartmentName,
	b.ScheduledStart,
	b.ScheduledEnd,
	b.StatusName,
	b.AppointmentID
from cte1 a
right join cte2 b
on a.AppointmentID=b.AppointmentID)

select
a.ProviderID,
a.FullName,
a.DepartmentName,
datediff(minute,a.ScheduledEnd,b.ScheduledStart) as gap
from cte3 a
left join cte3 b
on a.ProviderID = b.ProviderID
where datediff(minute,a.ScheduledEnd,b.ScheduledStart) > @Mingap ;


--Top noshow for last 30 days
Create or alter function dbo.fn_NoShow()
returns table
as
return
with cte as(
select
	p.ProviderID,
	p.FirstName,
	p.LastName,
	a.ScheduledStart,
	a.ScheduledEnd,
	aps.StatusName,
	a.AppointmentStatusID
from Provider p
join Appointment a
on p.providerid = a.providerid 
join AppointmentStatus Aps
on a.AppointmentStatusID = aps.AppointmentStatusID
join Department d
on p.DepartmentID=d.DepartmentID)

select 
	providerID,
	CONCAT(firstname,' ',LastName) as FullName,
	count(*) as Noshow#
from cte
where  AppointmentStatusID = 5
group by providerID, FirstName, LastName
