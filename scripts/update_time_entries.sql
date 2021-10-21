update employments e set
	time_policy_id = u.time_policy_id
from
	(select e.id as employee_id, u.current_time_policy_id as time_policy_id from users u inner join employees e on u.id = e.user_id where u.current_time_policy_id is not null) u
where
	e.employee_id = u.employee_id;

update time_entries te set
	employment_id = emp.employment_id
from
	(select u.id as user_id, emp.id as employment_id, emp.effective_date as effective_date, (select emp2.effective_date from employments emp2 where emp2.employee_id = emp.employee_id and emp2.effective_date > emp.effective_date order by emp2.effective_date limit 1) as end_effective_date from users u
	  inner join employees e on u.id = e.user_id
	  inner join employments emp on e.id = emp.employee_id) emp
where
	te.user_id = emp.user_id and te.event_date >= emp.effective_date and (emp.end_effective_date is null or te.event_date < emp.end_effective_date);
