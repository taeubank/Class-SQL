--Show me todays's schedualing gap, High no-show providers, and avalable slots by department.

/*
Outputs:
Todays Schedual for all providers- 
	partitioned by dept
	then provider
	providers with high nopshow occurences
	any empty time slots
*/

-- all the tea
create or alter procedure dbo.usp_Schedual
@targetdate date = null,
@Mingap int = 30
as 
begin
set @targetdate = isnull(@targetdate, cast(getdate() as date));
--Provider with scedualed Appointments for target date
--declare @targetdate date = cast(getdate() as date)
select*
from dbo.Providerschedual
where cast(ScheduledStart as date)= @targetdate

--Gaps in schedual-------They need more doctors
--declare @targetdate date = cast(getdate() as date)
--declare @Mingap int = 30
select*
from dbo.fn_ProviderGap(@targetdate,@Mingap)

--NoShow count
select *
from dbo.fn_NoShow()
order by Noshow# desc;
end

--RAW
select*
from dbo.Providerschedual


--All the Tea run
exec dbo.usp_Schedual 
@targetdate = '2002-01-01',
@Mingap = 30
