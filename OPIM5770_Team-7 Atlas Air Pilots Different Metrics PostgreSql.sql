create table published_schedule
as
select * from "Jul_Dec2019_published_schedule"
union
select * from "Jan_Jun2020_published_schedule"
union
select * from "Jan_Jun2021_published_schedule"
union
select * from "Jul_Dec2020_published_schedule";

create table actual_schedule
as
select * from "Jul_Dec2019_actual_schedule"
union
select * from "Jan_Jun2020_actual_schedule"
union
select * from "Jan_Jun2021_actual_schedule"
union
select * from "Jul_Dec2020_actual_schedule";

--Create Trip No Table
CREATE TABLE trip_nos (
	trip_no varchar(10) NULL,
	category varchar(50) NULL
);

--Insert data into trip no table from file


--Create Aircraft Types Table
CREATE TABLE aircraft_types (
	actype bpchar(3) NULL,
	aircrafttype bpchar(3) NULL,
	fleet numeric NULL
);

--Insert data into aircraft_types table from file


--Create Active Pilots Table
CREATE TABLE atlas_active_pilots (
	dept varchar(100) NULL,
	id numeric NULL,
	"position" varchar(100) NULL,
	hire_rehire timestamp NULL,
	age numeric NULL,
	previouscompany varchar(100) NULL,
	fleet numeric NULL,
	seat varchar(100) NULL
);
--Insert data into atlas_active_pilots table from file

--Create Attritioned Pilots Table
CREATE TABLE atlas_attrition (
	id numeric NULL,
	"position" varchar(100) NULL,
	hire_rehire timestamp NULL,
	term_date timestamp NULL,
	age_when_termed numeric NULL,
	resigned_for_company varchar(100) NULL,
	previous_company varchar(100) NULL,
	fleet numeric NULL,
	seat varchar(100) NULL
);
--Insert data into atlas_attrition table from file


-- Create table atlas_all_pilots
CREATE TABLE atlas_all_pilots (
	id numeric NULL,
	"position" varchar(100) NULL,
	hire_rehire timestamp NULL,
	age float8 NULL,
	fleet numeric NULL,
	seat varchar(100) NULL,
	pilotstatus text NULL
);

INSERT INTO ATLAS_ALL_PILOTS 
select  id, position, hire_rehire , age, fleet, seat, 'ACTIVE' from atlas_active_pilots aap
union
select  id, position, hire_rehire, age_when_termed  + DATE_PART('year',AGE(now()::DATE , term_date::DATE )) , fleet, seat, 'INACTIVE' from atlas_attrition aa;


-- Create table delay_data
CREATE TABLE delay_data (
	flightsequencenumber int4 NULL,
	flightdelaycode bpchar(3) NULL,
	delayminutes int4 NULL,
	delayhours varchar(10) NULL,
	newdelaydescription varchar(50) NULL,
	delaysequencenumber int4 NULL,
	secondary int2 NULL,
	departuredelay bool NULL
);
-- Insert into table from file

/*
Script 1 - Check Published Schedule Metrics
*/

with 
published_data as 
(
select 
ps.ID, 	--unique cremember identifier
aap.seat ,
aap.pilotstatus , 
ActivityDate, 	--date of activity (all times 0:00:00), UTC? 
PosonFlight, 	--position of crewmember on scheduled or actual flight: FO = first officer, CA = captain, A' = flight attendant
Base, 	--crewmember base at time of flight
TripNo, 	--trip identifier or leave/duty release indicator (X = not flying)
tn.category,
DeadHead, 	--DH = crewmember deadheaded (traveled on plane but was not part of crew)
TailNo, 	--aircraft tail # (unique aircraft identifier)
ps.ACType, 	--aircraft type 
at2.fleet ,
FlightNo, 	--flight number (non-unique; may be reused)
LegSeqNo, 	--indicates sequence of flight within trip (i.e. 1, 2, 3)
ActualBlockTime, 	--total time spent flying
TrainingDutyIndicator, 	--non-empty cells indicate crewmember released for training
PaidDayOff, 	--$ = paid day off
FltSeqNo, 	--unique flight identifier; when available can be used to link flights to FlightData table
DepartureStn, 	--departure station (IATA code)
ArrivalStn, 	--arrival station (IATA code)
ScheduledDepDt_UTC, 	--scheduled date of departure from departure station (all times 0:00:00), UTC
ScheduledDepTm_UTC 	--scheduled time of departure from departure station, UTC
from published_schedule ps inner join atlas_all_pilots aap on ps.id = aap.id 
left join trip_nos tn on ps.tripno  = tn.trip_no
left join aircraft_types at2 on ps.actype = at2.actype 
--where 
 --to_char(activitydate ,'MON') || '-' || extract(Year FROM activitydate) = 'JAN-2020' and
 --aap.seat  = 'CA' and
-- base = 'CVG'
--and ps.id = 64
order by
1, 3, 
to_timestamp(TO_CHAR(ScheduledDepDt_UTC::DATE,'MM-DD-YYYY') || ' ' || ScheduledDepTm_UTC, 'MM-DD-YYYY HH24:MI')
),
actual_data as
(
select 
as2.ID, 	--unique cremember identifier
aap.seat ,
aap.pilotstatus , 
ActivityDate, 	--date of activity (all times 0:00:00), UTC? 
PosonFlight, 	--position of crewmember on scheduled or actual flight: FO = first officer, CA = captain, A' = flight attendant
Base, 	--crewmember base at time of flight
TripNo, 	--trip identifier or leave/duty release indicator (X = not flying)
tn.category,
DeadHead, 	--DH = crewmember deadheaded (traveled on plane but was not part of crew)
TailNo, 	--aircraft tail # (unique aircraft identifier)
as2.ACType, 	--aircraft type
at2.fleet ,
FlightNo, 	--flight number (non-unique; may be reused)
LegSeqNo, 	--indicates sequence of flight within trip (i.e. 1, 2, 3)
ActualBlockTime, 	--total time spent flying
TrainingDutyIndicator, 	--non-empty cells indicate crewmember released for training
PaidDayOff, 	--$ = paid day off
FltSeqNo, 	--unique flight identifier; when available can be used to link flights to FlightData table
DepartureStn, 	--departure station (IATA code)
ArrivalStn, 	--arrival station (IATA code)
ScheduledDepDt_UTC, 	--scheduled date of departure from departure station (all times 0:00:00), UTC
ScheduledDepTm_UTC 	--scheduled time of departure from departure station, UTC
from actual_schedule as2 inner join atlas_all_pilots aap on as2.id = aap.id
left join trip_nos tn on as2.tripno  = tn.trip_no
left join aircraft_types at2 on as2.actype = at2.actype 
--where 
 --to_char(activitydate ,'MON') || '-' || extract(Year FROM activitydate) = 'JAN-2020' and
 --aap.seat  = 'CA' and
 --base = 'CVG' and
-- as2.id = 64
order by 1, 3, 
to_timestamp(TO_CHAR(ScheduledDepDt_UTC::DATE,'MM-DD-YYYY') || ' ' || replace (ScheduledDepTm_UTC,'24:00','00:00'), 'MM-DD-YYYY HH24:MI') 
) 
--select * from published_data where id = 9 and category is not null and to_char(activitydate ,'MON') || '-' || extract(Year FROM activitydate) = 'JUL-2019';
, PUBLISHED_MONTHLY_CATEGORY_DATA as 
(
select 
to_char(activitydate ,'MON') || '-' || extract(Year FROM activitydate)  MONTH_YEAR,
pd.id,
base,
pd.seat,
UPPER(category) CATEGORY,
count(distinct activitydate) TOTAL_DAYS,
count(distinct tripno) TOTAL_TYPE_USED
from published_data pd
where category is not null
group by 
to_char(activitydate ,'MON') || '-' || extract(Year FROM activitydate) ,
pd.id,
base,
seat, 
category
order by 
to_timestamp(to_char(activitydate ,'MON') || '-' || extract(Year FROM activitydate),'MON-YYYY'), 
base,
seat,
id 
)
, PUBLISHED_MCD as (
select  --* from MONTHLY_CATEGORY_DATA;
MONTH_YEAR,
id,
base,
seat,
max(case when (CATEGORY='OFF DUTY') then TOTAL_DAYS else NULL end) as OFFDUTY_DAYS,
max(case when (CATEGORY='RESERVE') then TOTAL_DAYS else NULL end) as RESERVE_DAYS,
max(case when (CATEGORY='TRAINING') then TOTAL_DAYS else NULL end) as TRAINING_DAYS,
max(case when (CATEGORY='TRAINING') then TOTAL_TYPE_USED else NULL end) as TRAINING_TRIPS
from PUBLISHED_MONTHLY_CATEGORY_DATA
group by 
MONTH_YEAR,
id,
base,
seat
order by to_timestamp(month_year,'MON-YYYY') , base, seat, id
)
, PUBLISHED_FLIGHT_HOURS as (
select 
to_char(activitydate ,'MON') || '-' || extract(Year FROM activitydate) month_year ,
id,
base,
seat,
--sum(actualblocktime) R2_Hours,
sum(case when trim(flightno) = 'R2' then actualblocktime else null end) as R2_Hours,
sum(case when trim(deadhead) = 'DH' then actualblocktime else null end) as Deadhead_Hours,
sum(case when (trim(deadhead) is null and trim(flightno) != 'R2' and actype is not null) then actualblocktime else null end) as flyingblock_hours,
count(distinct case when trim(deadhead) = 'DH' then (activitydate) else null end ) deadhead_trips,
count(distinct case when (trim(deadhead) is null and trim(flightno) != 'R2' and actype is not null)  then (fltseqno) else null end ) flying_trips
from published_data where category is null --and trim(flightno) = 'R2'
group by 
to_char(activitydate ,'MON') || '-' || extract(Year FROM activitydate) ,
id,
base,
seat
order by to_timestamp(to_char(activitydate ,'MON') || '-' || extract(Year FROM activitydate),'MON-YYYY'), base, seat, id
)
--select * from PUBLISHED_FLIGHT_HOURS;
, MATCHING_PVA_TRIPS as (
select
to_char(pd.activitydate ,'MON') || '-' || extract(Year FROM pd.activitydate) month_year ,
pd.id,
pd.base,
pd.seat,
count(*) MATCHING_TRIP_COUNT
from published_data pd inner join actual_data ad on pd.id = ad.id  and pd.fltseqno = ad.fltseqno and pd.base = ad.base
where pd.deadhead is null
group by 
to_char(pd.activitydate ,'MON') || '-' || extract(Year FROM pd.activitydate) ,
pd.id,
pd.base,
pd.seat
order by 
to_timestamp(to_char(pd.activitydate ,'MON') || '-' || extract(Year FROM pd.activitydate),'MON-YYYY'), pd.base, pd.seat, pd.id
)
select 
pm.*,
pfh.r2_hours,
pfh.deadhead_hours,
pfh.flyingblock_hours,
pfh.deadhead_trips,
pfh.flying_trips,
coalesce(mpt.MATCHING_TRIP_COUNT,0) 
from PUBLISHED_MCD pm left join PUBLISHED_FLIGHT_HOURS pfh 
on pm.month_year = pfh.month_year
and pm.id = pfh.id
and pm.base = pfh. base 
and pm.seat = pfh.seat
left join MATCHING_PVA_TRIPS mpt 
on pm.month_year = mpt.month_year
and pm.id = mpt.id
and pm.base = mpt. base 
and pm.seat = mpt.seat
order by 
to_timestamp(pm.month_year,'MON-YYYY'), pm.base, pm.seat, pm.id
;

/*
Script 1 - Ends
*/



/*
Script 2 - Check Actual Schedule Metrics
*/

with 
published_data as 
(
select 
ps.ID, 	--unique cremember identifier
aap.seat ,
aap.pilotstatus , 
ActivityDate, 	--date of activity (all times 0:00:00), UTC? 
PosonFlight, 	--position of crewmember on scheduled or actual flight: FO = first officer, CA = captain, A' = flight attendant
Base, 	--crewmember base at time of flight
TripNo, 	--trip identifier or leave/duty release indicator (X = not flying)
tn.category,
DeadHead, 	--DH = crewmember deadheaded (traveled on plane but was not part of crew)
TailNo, 	--aircraft tail # (unique aircraft identifier)
ps.ACType, 	--aircraft type 
at2.fleet ,
FlightNo, 	--flight number (non-unique; may be reused)
LegSeqNo, 	--indicates sequence of flight within trip (i.e. 1, 2, 3)
ActualBlockTime, 	--total time spent flying
TrainingDutyIndicator, 	--non-empty cells indicate crewmember released for training
PaidDayOff, 	--$ = paid day off
FltSeqNo, 	--unique flight identifier; when available can be used to link flights to FlightData table
DepartureStn, 	--departure station (IATA code)
ArrivalStn, 	--arrival station (IATA code)
ScheduledDepDt_UTC, 	--scheduled date of departure from departure station (all times 0:00:00), UTC
ScheduledDepTm_UTC 	--scheduled time of departure from departure station, UTC
from published_schedule ps inner join atlas_all_pilots aap on ps.id = aap.id 
left join trip_nos tn on ps.tripno  = tn.trip_no
left join aircraft_types at2 on ps.actype = at2.actype 
--where 
 --to_char(activitydate ,'MON') || '-' || extract(Year FROM activitydate) = 'JAN-2020' and
 --aap.seat  = 'CA' and
-- base = 'CVG'
--and ps.id = 64
order by
1, 3, 
to_timestamp(TO_CHAR(ScheduledDepDt_UTC::DATE,'MM-DD-YYYY') || ' ' || ScheduledDepTm_UTC, 'MM-DD-YYYY HH24:MI')
),
actual_data as
(
select 
as2.ID, 	--unique cremember identifier
aap.seat ,
aap.pilotstatus , 
ActivityDate, 	--date of activity (all times 0:00:00), UTC? 
PosonFlight, 	--position of crewmember on scheduled or actual flight: FO = first officer, CA = captain, A' = flight attendant
Base, 	--crewmember base at time of flight
TripNo, 	--trip identifier or leave/duty release indicator (X = not flying)
tn.category,
DeadHead, 	--DH = crewmember deadheaded (traveled on plane but was not part of crew)
TailNo, 	--aircraft tail # (unique aircraft identifier)
as2.ACType, 	--aircraft type
at2.fleet ,
FlightNo, 	--flight number (non-unique; may be reused)
LegSeqNo, 	--indicates sequence of flight within trip (i.e. 1, 2, 3)
ActualBlockTime, 	--total time spent flying
TrainingDutyIndicator, 	--non-empty cells indicate crewmember released for training
PaidDayOff, 	--$ = paid day off
FltSeqNo, 	--unique flight identifier; when available can be used to link flights to FlightData table
DepartureStn, 	--departure station (IATA code)
ArrivalStn, 	--arrival station (IATA code)
ScheduledDepDt_UTC, 	--scheduled date of departure from departure station (all times 0:00:00), UTC
ScheduledDepTm_UTC 	--scheduled time of departure from departure station, UTC
from actual_schedule as2 inner join atlas_all_pilots aap on as2.id = aap.id
left join trip_nos tn on as2.tripno  = tn.trip_no
left join aircraft_types at2 on as2.actype = at2.actype 
--where 
 --to_char(activitydate ,'MON') || '-' || extract(Year FROM activitydate) = 'JAN-2020' and
 --aap.seat  = 'CA' and
 --base = 'CVG' and
-- as2.id = 64
order by 1, 3, 
to_timestamp(TO_CHAR(ScheduledDepDt_UTC::DATE,'MM-DD-YYYY') || ' ' || replace (ScheduledDepTm_UTC,'24:00','00:00'), 'MM-DD-YYYY HH24:MI') 
) 
--select * from published_data where id = 9 and category is not null and to_char(activitydate ,'MON') || '-' || extract(Year FROM activitydate) = 'JUL-2019';
, ACTUAL_MONTHLY_CATEGORY_DATA as 
(
select 
to_char(activitydate ,'MON') || '-' || extract(Year FROM activitydate)  MONTH_YEAR,
pd.id,
base,
pd.seat,
UPPER(category) CATEGORY,
count(distinct activitydate) TOTAL_DAYS,
count(distinct tripno) TOTAL_TYPE_USED
from actual_data pd
where category is not null
group by 
to_char(activitydate ,'MON') || '-' || extract(Year FROM activitydate) ,
pd.id,
base,
seat, 
category
order by 
to_timestamp(to_char(activitydate ,'MON') || '-' || extract(Year FROM activitydate),'MON-YYYY'), 
base,
seat,
id 
)
, ACTUAL_MCD as (
select  --* from MONTHLY_CATEGORY_DATA;
MONTH_YEAR,
id,
base,
seat,
max(case when (CATEGORY='OFF DUTY') then TOTAL_DAYS else NULL end) as OFFDUTY_DAYS,
max(case when (CATEGORY='RESERVE') then TOTAL_DAYS else NULL end) as RESERVE_DAYS,
max(case when (CATEGORY='TRAINING') then TOTAL_DAYS else NULL end) as TRAINING_DAYS,
max(case when (CATEGORY='TRAINING') then TOTAL_TYPE_USED else NULL end) as TRAINING_TRIPS
from ACTUAL_MONTHLY_CATEGORY_DATA
group by 
MONTH_YEAR,
id,
base,
seat
order by to_timestamp(month_year,'MON-YYYY') , base, seat, id
)
, ACTUAL_FLIGHT_HOURS as (
select 
to_char(activitydate ,'MON') || '-' || extract(Year FROM activitydate) month_year ,
id,
base,
seat,
--sum(actualblocktime) R2_Hours,
sum(case when trim(flightno) = 'R2' then actualblocktime else null end) as R2_Hours,
sum(case when trim(deadhead) = 'DH' then actualblocktime else null end) as Deadhead_Hours,
sum(case when (trim(deadhead) is null and trim(flightno) != 'R2' and actype is not null) then actualblocktime else null end) as flyingblock_hours,
count(distinct case when trim(deadhead) = 'DH' then (activitydate) else null end ) deadhead_trips,
count(distinct case when (trim(deadhead) is null and trim(flightno) != 'R2' and actype is not null)  then (fltseqno) else null end ) flying_trips
from actual_data where category is null --and trim(flightno) = 'R2'
group by 
to_char(activitydate ,'MON') || '-' || extract(Year FROM activitydate) ,
id,
base,
seat
order by to_timestamp(to_char(activitydate ,'MON') || '-' || extract(Year FROM activitydate),'MON-YYYY'), base, seat, id
)
--select * from PUBLISHED_FLIGHT_HOURS;
select 
pm.*,
pfh.r2_hours,
pfh.deadhead_hours,
pfh.flyingblock_hours,
pfh.deadhead_trips,
pfh.flying_trips
from ACTUAL_MCD pm left join ACTUAL_FLIGHT_HOURS pfh 
on pm.month_year = pfh.month_year
and pm.id = pfh.id
and pm.base = pfh. base 
and pm.seat = pfh.seat
order by 
to_timestamp(pm.month_year,'MON-YYYY'), pm.base, pm.seat, pm.id
;

/*
Script 2 - Ends
*/


-- create published_schedule_aggregated_data
create table published_schedule_aggregated_data
(
MONTH_YEAR VARCHAR(10),
ID int,
BASE VARCHAR(5),
PILOT_POSITION VARCHAR(4),
OFFDUTY_DAYS INT,
RESERVE_DAYS INT,
TRAINING_DAYS INT,
TRAINING_TYPES INT,
R2_HOURS DECIMAL,
DEADHEAD_HOURS DECIMAL,
FLYINGBLOCKHOURS DECIMAL,
DEADHEAD_TRIPS INT,
FLYING_TRIPS INT,
PUBLISHED_TO_ACTUAL_COUNT INT
);

-- Insert data from Script 1 - Scroll above


-- create table actual_schedule_aggregated_data
create table actual_schedule_aggregated_data
(
MONTH_YEAR VARCHAR(10),
ID int,
BASE VARCHAR(5),
PILOT_POSITION VARCHAR(4),
OFFDUTY_DAYS INT,
RESERVE_DAYS INT,
TRAINING_DAYS INT,
TRAINING_TYPES INT,
R2_HOURS DECIMAL,
DEADHEAD_HOURS DECIMAL,
FLYINGBLOCKHOURS DECIMAL,
DEADHEAD_TRIPS INT,
FLYING_TRIPS INT
);

-- Insert data from Script 2 - Scroll above


/*
Script 3 - Published vs Actual Schedule Metrics
*/

select 
psad.id,
psad.month_year ,
psad.base,
psad.pilot_position ,
aap.age, aap.pilotstatus, aa.previous_company, aa.resigned_for_company,
psad.offduty_days p_offduty_days,
asad.offduty_days a_offduty_days,
psad.reserve_days p_reserve_days,
asad.reserve_days a_reserve_days,
psad.training_days p_training_days,
asad.training_days a_training_days,
psad.r2_hours p_r2_hours,
asad.r2_hours a_r2_hours,
psad.deadhead_hours p_deadhead_hours,
asad.deadhead_hours a_deadhead_hours,
psad.flyingblockhours p_flyingblockhours,
asad.flyingblockhours a_flyingblockhours,
psad.deadhead_trips p_deadhead_trips,
asad.deadhead_trips a_deadhead_trips,
psad.flying_trips p_flying_trips,
asad.flying_trips a_flying_trips,
psad.published_to_actual_count,
case when (psad.flying_trips != 0 and psad.flying_trips is not null) then (psad.published_to_actual_count::float/psad.flying_trips)*100 end published_to_actual_transfer 
from published_schedule_aggregated_data psad
inner join atlas_all_pilots aap on psad.id = aap.id 
left join atlas_attrition aa on psad.id = aa.id
left join atlas_active_pilots aap2 on aap2.id = psad.id
left join actual_schedule_aggregated_data asad 
on psad.id = asad.id 
and psad.month_year =asad.month_year 
and psad.base = asad.base 
and psad.pilot_position  = asad.pilot_position order by 1, to_timestamp(psad.month_year,'MON-YYYY') ;
/*
Script 3 - Ends
*/



/* 
Script 4 - Get Last Leg Seq No of Monthly Trips in Published Schedule
*/
create table Last_LegSeqNo_Published as 
with
published_data as
(
select 
as2.ID, 	--unique cremember identifier
aap.seat ,
aap.fleet Pilot_Fleet,
aap.pilotstatus , 
ActivityDate, 	--date of activity (all times 0:00:00), UTC? 
PosonFlight, 	--position of crewmember on scheduled or actual flight: FO = first officer, CA = captain, A' = flight attendant
Base, 	--crewmember base at time of flight
TripNo, 	--trip identifier or leave/duty release indicator (X = not flying)
tn.category,
DeadHead, 	--DH = crewmember deadheaded (traveled on plane but was not part of crew)
TailNo, 	--aircraft tail # (unique aircraft identifier)
as2.ACType, 	--aircraft type
at2.fleet ,
FlightNo, 	--flight number (non-unique; may be reused)
LegSeqNo, 	--indicates sequence of flight within trip (i.e. 1, 2, 3)
ActualBlockTime, 	--total time spent flying
TrainingDutyIndicator, 	--non-empty cells indicate crewmember released for training
PaidDayOff, 	--$ = paid day off
FltSeqNo, 	--unique flight identifier; when available can be used to link flights to FlightData table
DepartureStn, 	--departure station (IATA code)
ArrivalStn, 	--arrival station (IATA code)
ScheduledDepDt_UTC, 	--scheduled date of departure from departure station (all times 0:00:00), UTC
ScheduledDepTm_UTC 	--scheduled time of departure from departure station, UTC
--fd.flightactualblocktime ,
--dda.Total_Delay_hours 
from published_schedule as2 inner join atlas_all_pilots aap on as2.id = aap.id
left join trip_nos tn on as2.tripno  = tn.trip_no
left join aircraft_types at2 on as2.actype = at2.actype
--where 
 --to_char(activitydate ,'MON') || '-' || extract(Year FROM activitydate) = 'JAN-2020' and
 --aap.seat  = 'CA' and
 --base = 'CVG' and
-- as2.id = 64
order by 1, 3, 
to_timestamp(TO_CHAR(ScheduledDepDt_UTC::DATE,'MM-DD-YYYY') || ' ' || replace (ScheduledDepTm_UTC,'24:00','00:00'), 'MM-DD-YYYY HH24:MI') 
)
Select 
id,
base,
seat,
Pilot_Fleet,
tripno,
to_char(activitydate ,'MON') || '-' || extract(Year FROM activitydate) MONTH_YEAR,
max(legseqno) MAX_LEGSEQNO 
from published_data ad2 where category is null 
and departurestn != arrivalstn
--and trim(flightno) = 'R2'
--and ad2.id = ad.id and ad2.base = ad.base and ad2.tripno = ad.tripno and to_char(ad2.activitydate ,'MON') || '-' || extract(Year FROM ad2.activitydate)
--= to_char(ad.activitydate ,'MON') || '-' || extract(Year FROM ad.activitydate)
group by 
id,
base,
seat,
Pilot_Fleet,
tripno,
to_char(activitydate ,'MON') || '-' || extract(Year FROM activitydate)
order by 1, 6;
/* 
Script 4 - Ends
*/


/* 
Script 5 - Get Last Leg Seq No of Monthly Trips in Actual Schedule
*/
create table Last_LegSeqNo_Actual as 
with
actual_data as
(
select 
as2.ID, 	--unique cremember identifier
aap.seat ,
aap.fleet Pilot_Fleet,
aap.pilotstatus , 
ActivityDate, 	--date of activity (all times 0:00:00), UTC? 
PosonFlight, 	--position of crewmember on scheduled or actual flight: FO = first officer, CA = captain, A' = flight attendant
Base, 	--crewmember base at time of flight
TripNo, 	--trip identifier or leave/duty release indicator (X = not flying)
tn.category,
DeadHead, 	--DH = crewmember deadheaded (traveled on plane but was not part of crew)
TailNo, 	--aircraft tail # (unique aircraft identifier)
as2.ACType, 	--aircraft type
at2.fleet ,
FlightNo, 	--flight number (non-unique; may be reused)
LegSeqNo, 	--indicates sequence of flight within trip (i.e. 1, 2, 3)
ActualBlockTime, 	--total time spent flying
TrainingDutyIndicator, 	--non-empty cells indicate crewmember released for training
PaidDayOff, 	--$ = paid day off
FltSeqNo, 	--unique flight identifier; when available can be used to link flights to FlightData table
DepartureStn, 	--departure station (IATA code)
ArrivalStn, 	--arrival station (IATA code)
ScheduledDepDt_UTC, 	--scheduled date of departure from departure station (all times 0:00:00), UTC
ScheduledDepTm_UTC 	--scheduled time of departure from departure station, UTC
--fd.flightactualblocktime ,
--dda.Total_Delay_hours 
from actual_schedule as2 inner join atlas_all_pilots aap on as2.id = aap.id
left join trip_nos tn on as2.tripno  = tn.trip_no
left join aircraft_types at2 on as2.actype = at2.actype
--where 
 --to_char(activitydate ,'MON') || '-' || extract(Year FROM activitydate) = 'JAN-2020' and
 --aap.seat  = 'CA' and
 --base = 'CVG' and
-- as2.id = 64
order by 1, 3, 
to_timestamp(TO_CHAR(ScheduledDepDt_UTC::DATE,'MM-DD-YYYY') || ' ' || replace (ScheduledDepTm_UTC,'24:00','00:00'), 'MM-DD-YYYY HH24:MI') 
)
Select 
id,
base,
seat,
Pilot_Fleet,
tripno,
to_char(activitydate ,'MON') || '-' || extract(Year FROM activitydate) MONTH_YEAR,
max(legseqno) MAX_LEGSEQNO 
from actual_data ad2 where category is null 
and departurestn != arrivalstn
--and trim(flightno) = 'R2'
--and ad2.id = ad.id and ad2.base = ad.base and ad2.tripno = ad.tripno and to_char(ad2.activitydate ,'MON') || '-' || extract(Year FROM ad2.activitydate)
--= to_char(ad.activitydate ,'MON') || '-' || extract(Year FROM ad.activitydate)
group by 
id,
base,
seat,
Pilot_Fleet,
tripno,
to_char(activitydate ,'MON') || '-' || extract(Year FROM activitydate)
order by 1, 6;
/* 
Script 5 - Ends
*/

/*
Script 6 - Create table flight_data_with_delays
*/

CREATE TABLE flight_data_with_delays (
	airlinecode bpchar(4) NULL,
	flightsequencenumber int4 NULL,
	flightnumber int2 NULL,
	departstation bpchar(4) NULL,
	arrivalstation bpchar(4) NULL,
	flightoriginaldeparttimestamp timestamp NULL,
	flightoriginalarrivaltimestamp timestamp NULL,
	flightactualblocktime varchar(50) NULL,
	flightactualblocktimeminutes int4 NULL,
	flightouttimestamp timestamp NULL,
	flightofftimestamp timestamp NULL,
	flightontimestamp timestamp NULL,
	flightintimestamp timestamp NULL,
	contract varchar(30) NULL,
	flightservicetype varchar(20) NULL,
	flightcategory varchar(20) NULL,
	servicetypecode numeric NULL,
	aircrafttype varchar(5) NULL,
	aircraftregistration varchar(20) NULL,
	customer int4 NULL,
	total_delay_hours numeric NULL,
	total_delay_minutes int8 NULL
);
CREATE UNIQUE INDEX fdd_fltseqno ON public.flight_data_with_delays USING btree (flightsequencenumber);

-- Insert data using inner hoin between flight data and delay data table

/*
Script 6 - ends 
*/


/* 
Script 7  --Published Aggregated Data for Pilots based on Monthly Trips
*/
with
actual_data as
(
select 
as2.ID, 	--unique cremember identifier
aap.seat ,
aap.fleet Pilot_Fleet,
aap.pilotstatus , 
ActivityDate, 	--date of activity (all times 0:00:00), UTC? 
PosonFlight, 	--position of crewmember on scheduled or actual flight: FO = first officer, CA = captain, A' = flight attendant
Base, 	--crewmember base at time of flight
TripNo, 	--trip identifier or leave/duty release indicator (X = not flying)
tn.category,
DeadHead, 	--DH = crewmember deadheaded (traveled on plane but was not part of crew)
TailNo, 	--aircraft tail # (unique aircraft identifier)
as2.ACType, 	--aircraft type
at2.fleet ,
FlightNo, 	--flight number (non-unique; may be reused)
LegSeqNo, 	--indicates sequence of flight within trip (i.e. 1, 2, 3)
ActualBlockTime, 	--total time spent flying
TrainingDutyIndicator, 	--non-empty cells indicate crewmember released for training
PaidDayOff, 	--$ = paid day off
FltSeqNo, 	--unique flight identifier; when available can be used to link flights to FlightData table
DepartureStn, 	--departure station (IATA code)
ArrivalStn, 	--arrival station (IATA code)
ScheduledDepDt_UTC, 	--scheduled date of departure from departure station (all times 0:00:00), UTC
ScheduledDepTm_UTC, 	--scheduled time of departure from departure station, UTC
a.country BASE_COUNTRY,
a2.country DEPARTURE_COUNTRY,
a3.country ARRIVAL_COUNTRY,
case when (a2.country != 'USA' or a3.country != 'USA') then 'INTERNATIONAL' 
	 when a.country = 'USA' and (a2.country = 'USA' and a3.country = 'USA') then 'DOMESTIC'
	 else NULL end Trip_type
--fd.flightactualblocktime ,
--dda.Total_Delay_hours 
from published_schedule as2 inner join atlas_all_pilots aap on as2.id = aap.id
left join airports a on as2.base = a.iata_code
left join airports a2 on as2.departurestn = a2.iata_code 
left join airports a3 on as2.arrivalstn = a3.iata_code 
left join trip_nos tn on as2.tripno  = tn.trip_no
left join aircraft_types at2 on as2.actype = at2.actype
--where 
 --to_char(activitydate ,'MON') || '-' || extract(Year FROM activitydate) = 'JAN-2020' and
 --aap.seat  = 'CA' and
 --base = 'CVG' and
-- as2.id = 64
order by 1, 3, 
to_timestamp(TO_CHAR(ScheduledDepDt_UTC::DATE,'MM-DD-YYYY') || ' ' || replace (ScheduledDepTm_UTC,'24:00','00:00'), 'MM-DD-YYYY HH24:MI') 
)
--select * from actual_data where category is null order by id,activitydate, legseqno; --where  tripno  = 'R7008' and id = 3
, PUBLISHED_FLIGHT_HOURS as (
select 
id,
pilotstatus,
base,
seat,
Pilot_Fleet,
tripno,
MAX (case when trip_type = 'DOMESTIC' then 0 else 1 end) IS_INTERNATIONAL,
to_char(activitydate ,'MON') || '-' || extract(Year FROM activitydate)  MONTH_YEAR,
--sum(actualblocktime) R2_Hours,
sum(case when trim(flightno) = 'R2' then actualblocktime else null end) as R2_Hours,
sum(case when trim(deadhead) = 'DH' then actualblocktime else null end) as Deadhead_Hours,
sum(case when (trim(deadhead) is null and trim(flightno) != 'R2' and actype is not null) then actualblocktime else null end) as flyingblock_hours,
count(case when trim(deadhead) = 'DH' then trim(deadhead) else null end ) Total_deadhead_trips,
count(case when trim(deadhead) = 'DH' and legseqno = 1 then trim(deadhead) else null end ) Base_to_Destination_DH,
count(case when legseqno = (
Select max_legseqno from Last_LegSeqNo_Published ad2
where ad2.id = ad.id and ad2.base = ad.base and ad2.seat = ad.seat and ad2.pilot_fleet = ad.pilot_fleet and ad2.tripno = ad.tripno and 
ad2.MONTH_YEAR
=
to_char(ad.activitydate ,'MON') || '-' || extract(Year FROM ad.activitydate)
)
and trim(deadhead) = 'DH' then trim(deadhead) else null end) Arrival_to_Base_DH,
count(distinct case when (trim(deadhead) is null and trim(flightno) != 'R2' and actype is not null)  then (legseqno) else null end ) flying_trips
, count (distinct activitydate) as TRIPLENGTH
, count (distinct case when posonflight is null then activitydate end ) as Total_Layovers
from actual_data ad
where category is null --and trim(flightno) = 'R2'
group by 
id,
pilotstatus,
base,
seat,
Pilot_Fleet,
tripno,
to_char(activitydate ,'MON') || '-' || extract(Year FROM activitydate) 
order by id, to_timestamp(to_char(activitydate ,'MON') || '-' || extract(Year FROM activitydate),'MON-YYYY'), tripno
)
select * from PUBLISHED_FLIGHT_HOURS ;

/* 
Script 7 End
*/


/* 
Script 8 --Actual Aggregated Data for Pilots based on Monthly Trips 
*/
with
actual_data as
(
select 
as2.ID, 	--unique cremember identifier
aap.seat ,
aap.fleet Pilot_Fleet,
aap.pilotstatus , 
ActivityDate, 	--date of activity (all times 0:00:00), UTC? 
PosonFlight, 	--position of crewmember on scheduled or actual flight: FO = first officer, CA = captain, A' = flight attendant
Base, 	--crewmember base at time of flight
TripNo, 	--trip identifier or leave/duty release indicator (X = not flying)
tn.category,
DeadHead, 	--DH = crewmember deadheaded (traveled on plane but was not part of crew)
TailNo, 	--aircraft tail # (unique aircraft identifier)
as2.ACType, 	--aircraft type
at2.fleet ,
FlightNo, 	--flight number (non-unique; may be reused)
LegSeqNo, 	--indicates sequence of flight within trip (i.e. 1, 2, 3)
ActualBlockTime, 	--total time spent flying
TrainingDutyIndicator, 	--non-empty cells indicate crewmember released for training
PaidDayOff, 	--$ = paid day off
FltSeqNo, 	--unique flight identifier; when available can be used to link flights to FlightData table
DepartureStn, 	--departure station (IATA code)
ArrivalStn, 	--arrival station (IATA code)
ScheduledDepDt_UTC, 	--scheduled date of departure from departure station (all times 0:00:00), UTC
ScheduledDepTm_UTC, 	--scheduled time of departure from departure station, UTC
a.country BASE_COUNTRY,
a2.country DEPARTURE_COUNTRY,
a3.country ARRIVAL_COUNTRY,
case when (a2.country != 'USA' or a3.country != 'USA') then 'INTERNATIONAL' 
	 when a.country = 'USA' and (a2.country = 'USA' and a3.country = 'USA') then 'DOMESTIC'
	 else NULL end Trip_type
--fd.flightactualblocktime ,
--dda.Total_Delay_hours 
from actual_schedule as2 inner join atlas_all_pilots aap on as2.id = aap.id
left join airports a on as2.base = a.iata_code
left join airports a2 on as2.departurestn = a2.iata_code 
left join airports a3 on as2.arrivalstn = a3.iata_code 
left join trip_nos tn on as2.tripno  = tn.trip_no
left join aircraft_types at2 on as2.actype = at2.actype
order by 1, 3, 
to_timestamp(TO_CHAR(ScheduledDepDt_UTC::DATE,'MM-DD-YYYY') || ' ' || replace (ScheduledDepTm_UTC,'24:00','00:00'), 'MM-DD-YYYY HH24:MI') 
)
--select * from actual_data where legseqno = 1; --where  tripno  = 'R7008' and id = 3
, ACTUAL_FLIGHT_HOURS as (
select 
id,
pilotstatus,
base,
seat,
Pilot_Fleet,
tripno,
MAX (case when trip_type = 'DOMESTIC' then 0 else 1 end) IS_INTERNATIONAL,
to_char(activitydate ,'MON') || '-' || extract(Year FROM activitydate)  MONTH_YEAR,
--sum(actualblocktime) R2_Hours,
sum(case when trim(flightno) = 'R2' then actualblocktime else null end) as R2_Hours,
sum(case when trim(deadhead) = 'DH' then actualblocktime else null end) as Deadhead_Hours,
sum(case when (trim(deadhead) is null and trim(flightno) != 'R2' and actype is not null) then actualblocktime else null end) as flyingblock_hours,
count(case when trim(deadhead) = 'DH' then trim(deadhead) else null end ) Total_deadhead_trips,
count(case when trim(deadhead) = 'DH' and legseqno = 1 then trim(deadhead) else null end ) Base_to_Destination_DH,
count(case when legseqno = (
Select max_legseqno from Last_LegSeqNo_Actual ad2
where ad2.id = ad.id and ad2.base = ad.base and ad2.seat = ad.seat and ad2.pilot_fleet = ad.pilot_fleet and ad2.tripno = ad.tripno and 
ad2.MONTH_YEAR
=
to_char(ad.activitydate ,'MON') || '-' || extract(Year FROM ad.activitydate)
)
and trim(deadhead) = 'DH' then trim(deadhead) else null end) Arrival_to_Base_DH,
count(distinct case when (trim(deadhead) is null and trim(flightno) != 'R2' and actype is not null)  then (legseqno) else null end ) flying_trips
,sum(case when total_delay_hours is not null then total_delay_hours else null end) as Total_Delay_hours
, count (distinct activitydate) as TRIPLENGTH
, count (distinct case when posonflight is null then activitydate end ) as Total_Layovers
from actual_data ad
--left join flight_data fd on ad.fltseqno = fd.flightsequencenumber 
left join flight_data_with_delays fdd on ad.fltseqno = fdd.flightsequencenumber 
where category is null --and trim(flightno) = 'R2'
group by 
id,
pilotstatus,
base,
seat,
Pilot_Fleet,
tripno,
to_char(activitydate ,'MON') || '-' || extract(Year FROM activitydate) 
order by id, to_timestamp(to_char(activitydate ,'MON') || '-' || extract(Year FROM activitydate),'MON-YYYY'), tripno
)
select * from ACTUAL_FLIGHT_HOURS ;
/* 
Script 8 -- Ends
*/