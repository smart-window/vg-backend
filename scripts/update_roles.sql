delete from user_roles
	where user_id in (select ur.user_id from user_roles ur
		inner join roles r on ur.role_id = r.id
		where r.slug in ('VGSales:ICPEmployeeReporter', 'VGSales:ICPEmployeeManager')
		group by ur.user_id having count(*) > 1) and role_id = (select id from roles where slug = 'VGSales:ICPEmployeeReporter');

delete from user_roles
	where user_id in (select ur.user_id from user_roles ur
		inner join roles r on ur.role_id = r.id
		where r.slug in ('VGSales:PTOManager', 'VGSales:ClientPTOApprover')
		group by ur.user_id having count(*) > 1) and role_id = (select id from roles where slug = 'VGSales:ClientPTOApprover');

update user_roles ur
  set role_id = case
    when ur.role_id = (select id from roles where slug = 'VGSales:RegionalDirector') then (select id from roles where slug = 'RegionalDirector')
    when ur.role_id = (select id from roles where slug = 'VGSales:ICPEmployeeReporter') then (select id from roles where slug = 'PartnerManager')
    when ur.role_id = (select id from roles where slug = 'VGSales:ICPEmployeeManager') then (select id from roles where slug = 'PartnerManager')
    when ur.role_id = (select id from roles where slug = 'VGSales:CAA') then (select id from roles where slug = 'ClientAccountAssociate')
    when ur.role_id = (select id from roles where slug = 'VGSales:VGExecutive') then (select id from roles where slug = 'Executive')
    when ur.role_id = (select id from roles where slug = 'VGSales:HRManager') then (select id from roles where slug = 'HRManager')
    when ur.role_id = (select id from roles where slug = 'VGSales:VGRAM') then (select id from roles where slug = 'RegionalAccountManager')
    when ur.role_id = (select id from roles where slug = 'VGSales:PTOManager') then (select id from roles where slug = 'PTOManager')
    when ur.role_id = (select id from roles where slug = 'VGSales:CSM') then (select id from roles where slug = 'ClientFinanceManager')
    when ur.role_id = (select id from roles where slug = 'VGSales:PayrollTeam') then (select id from roles where slug = 'PayrollTeam')
    when ur.role_id = (select id from roles where slug = 'VGSales:CAL') then (select id from roles where slug = 'ClientAccountManager')
    when ur.role_id = (select id from roles where slug = 'VGSales:HRSpecialist') then (select id from roles where slug = 'HRSpecialist')
    when ur.role_id = (select id from roles where slug = 'VGSales:RAA') then (select id from roles where slug = 'RegionalAccountAssociate')
    when ur.role_id = (select id from roles where slug = 'VGSales:ImmigrationManager') then (select id from roles where slug = 'ImmigrationManager')
    when ur.role_id = (select id from roles where slug = 'VGSales:SeniorManager') then (select id from roles where slug = 'SeniorManager')
    when ur.role_id = (select id from roles where slug = 'VGSales:VGNetworkTeam') then (select id from roles where slug = 'NetworkTeam')
    when ur.role_id = (select id from roles where slug = 'VGSales:ImmigrationAssociate') then (select id from roles where slug = 'ImmigrationAssociate')
    when ur.role_id = (select id from roles where slug = 'VGSales:ClientPTOApprover') then (select id from roles where slug = 'PTOManager')
    else ur.role_id
  end;

delete from user_roles ur using roles r where r.slug in ('VGSales:CSAdmin', 'VGSales:ClientPayrollManager', 'VGSales:ClientPayrollReporter', 'VGSales:ClientPTOReporter', 'VGSales:ClientEEPersonalInfoReporter', 'VGSales:ClientEEPersonalInfoManager', 'VGSales:ClientDocumentManager', 'VGSales:RegionalDirector', 'VGSales:ICPEmployeeReporter', 'VGSales:ICPEmployeeManager', 'VGSales:CAA', 'VGSales:VGExecutive', 'VGSales:HRManager', 'VGSales:VGRAM', 'VGSales:PTOManager', 'VGSales:CSM', 'VGSales:PayrollTeam', 'VGSales:CSAdmin', 'VGSales:CAL', 'VGSales:HRSpecialist', 'VGSales:RAA', 'VGSales:ImmigrationManager', 'VGSales:SeniorManager', 'VGSales:VGNetworkTeam', 'VGSales:ImmigrationAssociate', 'VGSales:ClientPTOApprover') and r.id = ur.role_id;
delete from role_assignments ra using roles r where r.slug in ('VGSales:CSAdmin', 'VGSales:ClientPayrollManager', 'VGSales:ClientPayrollReporter', 'VGSales:ClientPTOReporter', 'VGSales:ClientEEPersonalInfoReporter', 'VGSales:ClientEEPersonalInfoManager', 'VGSales:ClientDocumentManager', 'VGSales:RegionalDirector', 'VGSales:ICPEmployeeReporter', 'VGSales:ICPEmployeeManager', 'VGSales:CAA', 'VGSales:VGExecutive', 'VGSales:HRManager', 'VGSales:VGRAM', 'VGSales:PTOManager', 'VGSales:CSM', 'VGSales:PayrollTeam', 'VGSales:CSAdmin', 'VGSales:CAL', 'VGSales:HRSpecialist', 'VGSales:RAA', 'VGSales:ImmigrationManager', 'VGSales:SeniorManager', 'VGSales:VGNetworkTeam', 'VGSales:ImmigrationAssociate', 'VGSales:ClientPTOApprover') and r.id = ra.role_id;
delete from roles r where r.slug in ('VGSales:CSAdmin', 'VGSales:ClientPayrollManager', 'VGSales:ClientPayrollReporter', 'VGSales:ClientPTOReporter', 'VGSales:ClientEEPersonalInfoReporter', 'VGSales:ClientEEPersonalInfoManager', 'VGSales:ClientDocumentManager', 'VGSales:RegionalDirector', 'VGSales:ICPEmployeeReporter', 'VGSales:ICPEmployeeManager', 'VGSales:CAA', 'VGSales:VGExecutive', 'VGSales:HRManager', 'VGSales:VGRAM', 'VGSales:PTOManager', 'VGSales:CSM', 'VGSales:PayrollTeam', 'VGSales:CSAdmin', 'VGSales:CAL', 'VGSales:HRSpecialist', 'VGSales:RAA', 'VGSales:ImmigrationManager', 'VGSales:SeniorManager', 'VGSales:VGNetworkTeam', 'VGSales:ImmigrationAssociate', 'VGSales:ClientPTOApprover');
