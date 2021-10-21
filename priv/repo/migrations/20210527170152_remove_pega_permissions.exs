defmodule Velocity.Repo.Migrations.RemovePegaPermissions do
  use Ecto.Migration

  def change do
    # calendars
    execute "delete from group_permissions gp using permissions p where p.slug = 'calendars' and gp.permission_id = p.id;"
    execute "delete from permissions where slug = 'calendars';"
    # case-management
    execute "delete from group_permissions gp using permissions p where p.slug = 'case-management' and gp.permission_id = p.id;"
    execute "delete from permissions where slug = 'case-management';"
    # client-manager-profile
    execute "delete from group_permissions gp using permissions p where p.slug = 'client-manager-profile' and gp.permission_id = p.id;"
    execute "delete from permissions where slug = 'client-manager-profile';"
    # client-profile
    execute "delete from group_permissions gp using permissions p where p.slug = 'client-profile' and gp.permission_id = p.id;"
    execute "delete from permissions where slug = 'client-profile';"
    # country-information
    execute "delete from group_permissions gp using permissions p where p.slug = 'country-information' and gp.permission_id = p.id;"
    execute "delete from permissions where slug = 'country-information';"
    # employee-profile
    execute "delete from group_permissions gp using permissions p where p.slug = 'employee-profile' and gp.permission_id = p.id;"
    execute "delete from permissions where slug = 'employee-profile';"
    # gross-payroll-report
    execute "delete from group_permissions gp using permissions p where p.slug = 'gross-payroll-report' and gp.permission_id = p.id;"
    execute "delete from permissions where slug = 'gross-payroll-report';"
    # home
    execute "delete from group_permissions gp using permissions p where p.slug = 'home' and gp.permission_id = p.id;"
    execute "delete from permissions where slug = 'home';"
    # icp-contact-profile
    execute "delete from group_permissions gp using permissions p where p.slug = 'icp-contact-profile' and gp.permission_id = p.id;"
    execute "delete from permissions where slug = 'icp-contact-profile';"
    # icp-profile
    execute "delete from group_permissions gp using permissions p where p.slug = 'icp-profile' and gp.permission_id = p.id;"
    execute "delete from permissions where slug = 'icp-profile';"
    # notification-settings
    execute "delete from group_permissions gp using permissions p where p.slug = 'notification-settings' and gp.permission_id = p.id;"
    execute "delete from permissions where slug = 'notification-settings';"
    # payroll-calendars
    execute "delete from group_permissions gp using permissions p where p.slug = 'payroll-calendars' and gp.permission_id = p.id;"
    execute "delete from permissions where slug = 'payroll-calendars';"
    # payroll-deactivation
    execute "delete from group_permissions gp using permissions p where p.slug = 'payroll-deactivation' and gp.permission_id = p.id;"
    execute "delete from permissions where slug = 'payroll-deactivation';"
    # payroll-request
    execute "delete from group_permissions gp using permissions p where p.slug = 'payroll-request' and gp.permission_id = p.id;"
    execute "delete from permissions where slug = 'payroll-request';"
    # pto-accrual-policies
    execute "delete from group_permissions gp using permissions p where p.slug = 'pto-accrual-policies' and gp.permission_id = p.id;"
    execute "delete from permissions where slug = 'pto-accrual-policies';"
    # pto-request
    execute "delete from group_permissions gp using permissions p where p.slug = 'pto-request' and gp.permission_id = p.id;"
    execute "delete from permissions where slug = 'pto-request';"
    # reports
    execute "delete from group_permissions gp using permissions p where p.slug = 'reports' and gp.permission_id = p.id;"
    execute "delete from permissions where slug = 'reports';"
    # search
    execute "delete from group_permissions gp using permissions p where p.slug = 'search' and gp.permission_id = p.id;"
    execute "delete from permissions where slug = 'search';"
    # support-case
    execute "delete from group_permissions gp using permissions p where p.slug = 'support-case' and gp.permission_id = p.id;"
    execute "delete from permissions where slug = 'support-case';"
    # tags
    execute "delete from group_permissions gp using permissions p where p.slug = 'tags' and gp.permission_id = p.id;"
    execute "delete from permissions where slug = 'tags';"
    # unit-management
    execute "delete from group_permissions gp using permissions p where p.slug = 'unit-management' and gp.permission_id = p.id;"
    execute "delete from permissions where slug = 'unit-management';"
    # upload-documents
    execute "delete from group_permissions gp using permissions p where p.slug = 'upload-documents' and gp.permission_id = p.id;"
    execute "delete from permissions where slug = 'upload-documents';"
    # vg-employee-profile
    execute "delete from group_permissions gp using permissions p where p.slug = 'vg-employee-profile' and gp.permission_id = p.id;"
    execute "delete from permissions where slug = 'vg-employee-profile';"
    # manage-my-profile
    execute "delete from group_permissions gp using permissions p where p.slug = 'manage-my-profile' and gp.permission_id = p.id;"
    execute "delete from permissions where slug = 'manage-my-profile';"
  end
end
