with recursive cte as(
		with cte_data as 
				(select v.id, v.emp_id, v.name, v.from_dt, v.to_dt
				, l.balance as leave_balance, count(d.dates) as vacation_days
				, row_number() over(partition by v.emp_id order by v.emp_id, v.id) as rn
				from vacation_plans v
				cross join lateral (select cast(dates as date) as dates, trim(to_char(dates, 'Day')) as day
									from generate_series(v.from_dt, v.to_dt, '1 Day') dates) d
				join leave_balance l on l.emp_id = v.emp_id
				where day not in ('Saturday', 'Sunday')
				group by v.id, v.emp_id, v.from_dt, v.to_dt, l.balance
				order by v.emp_id, v.id)
		select *, (leave_balance-vacation_days) as remaining_balance  
		from cte_data
		where rn=1
		union all
		select cd.*, (cte.remaining_balance - cd.vacation_days) as remaining_balance
		from cte
		join cte_data cd on cd.rn = cte.rn+1 and cte.emp_id = cd.emp_id
	
   )
select id, emp_id, name, from_dt, to_dt, leave_balance, vacation_days
, case when remaining_balance < 0 then 'Insufficient Leave Balance' else 'Approved' end as status
from cte;


