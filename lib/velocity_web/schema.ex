defmodule VelocityWeb.Schema do
  @moduledoc """
  Velocity GQL Schema
  Currently grouped by Entity with a comment block, but
  as this grows we might consider splitting into separate files.
  """
  use Absinthe.Schema

  import_types(Absinthe.Plug.Types)
  import_types(Absinthe.Type.Custom)
  import_types(VelocityWeb.Schema.CountryTypes)
  import_types(VelocityWeb.Schema.ClientContactTypes)
  import_types(VelocityWeb.Schema.ClientTypes)
  import_types(VelocityWeb.Schema.AddressTypes)
  import_types(VelocityWeb.Schema.SharedTypes)
  import_types(VelocityWeb.Schema.Json)
  import_types(VelocityWeb.Schema.UserTypes)
  import_types(VelocityWeb.Schema.FormTypes)
  import_types(VelocityWeb.Schema.RoleTypes)
  import_types(VelocityWeb.Schema.PermissionTypes)
  import_types(VelocityWeb.Schema.PtoTypes)
  import_types(VelocityWeb.Schema.TimeTrackingTypes)
  import_types(VelocityWeb.Schema.ProcessTypes)
  import_types(VelocityWeb.Schema.TrainingTypes)
  import_types(VelocityWeb.Schema.DocumentTypes)
  import_types(VelocityWeb.Schema.PartnerTypes)
  import_types(VelocityWeb.Schema.PartnerOperatingCountryTypes)
  import_types(VelocityWeb.Schema.PartnerOperatingCountryServiceTypes)
  import_types(VelocityWeb.Schema.PartnerContactTypes)
  import_types(VelocityWeb.Schema.JobTypes)
  import_types(VelocityWeb.Schema.ClientManagerTypes)
  import_types(VelocityWeb.Schema.ContractTypes)
  import_types(VelocityWeb.Schema.EmployeeTypes)
  import_types(VelocityWeb.Schema.EmploymentTypes)
  import_types(VelocityWeb.Schema.EmploymentClientManagerTypes)
  import_types(VelocityWeb.Schema.RegionTypes)
  import_types(VelocityWeb.Schema.EmployeeOnboardingTypes)
  import_types(VelocityWeb.Schema.ClientOnboardingTypes)
  import_types(VelocityWeb.Schema.PartnerManagerTypes)
  import_types(VelocityWeb.Schema.EmailTemplateTypes)
  import_types(VelocityWeb.Schema.ClientOperatingCountryTypes)
  import_types(VelocityWeb.Schema.MeetingTypes)
  import_types(VelocityWeb.Schema.SentEmailTypes)
  import_types(VelocityWeb.Schema.TeamTypes)
  import_types(VelocityWeb.Schema.ClientContactTypes)
  import_types(VelocityWeb.Schema.PartnerOperatingCountryTypes)
  import_types(VelocityWeb.Schema.InternalEmployeeTypes)
  import_types(VelocityWeb.Schema.RoleTypes)

  alias VelocityWeb.Resolvers
  alias VelocityWeb.Resolvers.Pto
  alias VelocityWeb.Resolvers.Training.EmployeeTrainings
  alias VelocityWeb.Resolvers.Training.Trainings

  query do
    # Global
    @desc "get permissions for the current user"
    field :permissions, list_of(:permission) do
      resolve(&Resolvers.Permissions.for_current_user/2)
    end

    @desc "get role assignments for the current user"
    field :role_assignments, list_of(:role_assignment) do
      resolve(&Resolvers.RoleAssignments.for_current_user/2)
    end

    @desc "current user"
    field :current_user, :user do
      resolve(&Resolvers.CurrentUser.get/2)
    end

    @desc "get all clients in the system"
    field :clients, list_of(:client) do
      resolve(&Resolvers.Clients.all/2)
    end

    @desc "get all regions in the system"
    field :regions, list_of(:region) do
      resolve(&Resolvers.Regions.all/2)
    end

    @desc "get all countries in the system"
    field :countries, list_of(:country) do
      resolve(&Resolvers.Countries.all/2)
    end

    @desc "get all partners in the system"
    field :partners, list_of(:partner) do
      resolve(&Resolvers.Partners.all/2)
    end

    @desc "get all client managers"
    field :client_managers, list_of(:client_manager) do
      resolve(&Resolvers.ClientManagers.all/2)
    end

    field :csr_users, list_of(:user) do
      resolve(&Resolvers.CsrUsers.csr_users/2)
    end

    @desc "get all csr roles"
    field :csr_roles, list_of(:role) do
      resolve(&Resolvers.Roles.csr_roles/2)
    end

    @desc "get all client manager roles"
    field :client_manager_roles, list_of(:role) do
      resolve(&Resolvers.Roles.client_manager_roles/2)
    end

    # Forms
    @desc "get fields for a particular form, based on the current user and their country of employment"
    field :form_fields_for_current_user, list_of(:form_field) do
      arg(:form_slug, non_null(:id))

      resolve(&Resolvers.Forms.get_fields_with_values_for_current_user/2)
    end

    @desc "get fields for a particular form, based on a passed in user and their country of employment"
    field :form_fields_for_user, list_of(:form_field) do
      arg(:form_slug, non_null(:id))
      arg(:user_id, non_null(:id))

      resolve(&Resolvers.Forms.get_fields_with_values_for_user/2)
    end

    @desc "get a list of forms with fields/values, based on the current user and their country of employment"
    field :forms_by_slug_for_current_user, list_of(:form) do
      arg(:form_slugs, non_null(list_of(:id)))

      resolve(&Resolvers.Forms.get_forms_fields_and_values_for_current_user/2)
    end

    @desc "get a list of forms with fields/values, based on a passed in user and their country of employment"
    field :forms_by_slug_for_user, list_of(:form) do
      arg(:form_slugs, non_null(list_of(:id)))
      arg(:user_id, non_null(:id))

      resolve(&Resolvers.Forms.get_forms_fields_and_values_for_user/2)
    end

    # Process / Tasks
    @desc "retrieves a process"
    field :process, :process do
      arg(:id, non_null(:id))
      arg(:user_ids, list_of(:integer))

      resolve(&Resolvers.Processes.get/2)
    end

    @desc "retrieves all processes"
    field :processes, list_of(:process) do
      resolve(&Resolvers.Processes.all/2)
    end

    @desc "retrieves a task"
    field :task, :task do
      arg(:id, non_null(:id))

      resolve(&Resolvers.Tasks.get/2)
    end

    @desc "retrieves an email template by name"
    field :email_template_by_name, :email_template do
      arg(:name, non_null(:id))
      arg(:country_id, :id)
      arg(:variables, list_of(:email_variable), default_value: [])

      resolve(&Resolvers.EmailTemplates.get_by_name/2)
    end

    # PTO
    field :accrual_policies, list_of(:accrual_policy) do
      resolve(&Pto.AccrualPolicies.all/2)
    end

    field :accrual_policies_report, :accrual_policies_report do
      arg(:page_size, :integer)
      arg(:sort_column, :string)
      arg(:sort_direction, :string)
      arg(:last_id, :id, default_value: 0)
      arg(:last_value, :string, default_value: "")
      arg(:filter_by, list_of(:filter_by), default_value: [])
      arg(:search_by, :string, default_value: "")
      resolve(&Pto.AccrualPolicies.accrual_policies_report/2)
    end

    field :accrual_policy, :accrual_policy do
      arg(:accrual_policy_id, :id)

      resolve(&Pto.AccrualPolicies.get/2)
    end

    field :ledgers, list_of(:pto_ledger) do
      arg(:user_id, :id)
      arg(:accrual_policy_id, :id)

      resolve(&Pto.Ledgers.list/2)
    end

    field :last_ledger_entry, :pto_ledger do
      arg(:user_id, :id)
      arg(:accrual_policy_id, :id)

      resolve(&Pto.Ledgers.last_ledger_entry/2)
    end

    field :users, list_of(:user) do
      resolve(&Pto.Users.with_policies/2)
    end

    field :user_policies, list_of(:user_policy) do
      arg(:user_id, :id)
      arg(:email, :string)

      resolve(&Pto.UserPolicies.for_user/2)
    end

    # Time Tracking
    @desc "get a range-bounded list of time entries for current user and policy"
    field :time_entries, list_of(:time_entry) do
      arg(:start_date, non_null(:date))
      arg(:end_date, non_null(:date))
      resolve(&Resolvers.TimeTrackers.list_time_entries/2)
    end

    @desc "get time entries"
    # This endpoint will populate the following virtual fields on time_entry:
    #   user_okta_user_uid
    #   user_last_name
    #   user_first_name
    #   user_full_name
    #   user_client_name
    #   user_work_address_country_name
    #   time_type_slug
    field :time_entries_report, :time_entries_report do
      arg(:page_size, :integer, default_value: 50)
      arg(:sort_column, :string, default_value: "event_date")
      arg(:sort_direction, :string, default_value: "desc")
      arg(:last_id, :id, default_value: 0)
      arg(:last_value, :string, default_value: "")
      arg(:filter_by, list_of(:filter_by), default_value: [])
      arg(:search_by, :string, default_value: "")
      resolve(&Resolvers.TimeTrackers.paged_time_entries/2)
    end

    @desc "retrieves the time types for the users current time policy"
    field :time_types, list_of(:time_type) do
      resolve(&Resolvers.TimeTrackers.get_time_types/2)
    end

    @desc "retrieves all time types"
    field :all_time_types, list_of(:time_type) do
      resolve(&Resolvers.TimeTrackers.get_all_time_types/2)
    end

    # Training
    @desc "get trainings for a users country"
    field :trainings, list_of(:training) do
      resolve(&Trainings.for_users_country/2)
    end

    @desc "get employee trainings for a user"
    field :employee_trainings, list_of(:employee_training) do
      resolve(&EmployeeTrainings.for_current_user/2)
    end

    @desc "get paged trainings"
    #  This endpoint will populate the following virtual fields on employee_training:
    #   user_last_name
    #   user_first_name
    #   user_full_name
    #   user_okta_user_uid
    #   training_name
    #   user_client_name
    #   user_work_address_country_name
    field :employee_trainings_report, :employee_trainings_report do
      arg(:page_size, :integer)
      arg(:sort_column, :string)
      arg(:sort_direction, :string)
      arg(:last_id, :id, default_value: 0)
      arg(:last_value, :string, default_value: "")
      arg(:filter_by, list_of(:filter_by), default_value: [])
      arg(:search_by, :string, default_value: "")
      resolve(&EmployeeTrainings.employee_trainings_report/2)
    end

    # Documents
    @desc "get a document template"
    field :document_template, :document_template do
      arg(:id, non_null(:id))

      resolve(&Resolvers.Documents.get_template/2)
    end

    @desc "get a document template report"
    field :document_templates_report, :paginated_document_templates_report do
      arg(:page_size, :integer)
      arg(:sort_column, :string)
      arg(:sort_direction, :string)
      arg(:last_id, :id, default_value: 0)
      arg(:last_value, :string, default_value: "")
      arg(:filter_by, list_of(:filter_by), default_value: [])
      arg(:search_by, :string, default_value: "")
      resolve(&Resolvers.Documents.templates_report/2)
    end

    @desc "get a list of documents"
    field :documents, list_of(:document) do
      resolve(&Resolvers.Documents.all/2)
    end

    @desc "get a list of documents for the current user"
    field :current_user_documents, list_of(:document) do
      resolve(&Resolvers.Documents.all_for_current_user/2)
    end

    @desc "get a list of documents for a user"
    field :user_documents, list_of(:document) do
      arg(:user_id, non_null(:id))

      resolve(&Resolvers.Documents.all_for_user/2)
    end

    @desc "get a list of documents for a client"
    field :client_documents, list_of(:document) do
      arg(:client_id, non_null(:id))

      resolve(&Resolvers.Documents.all_for_client/2)
    end

    @desc "get a document"
    field :document, :document do
      arg(:id, :id)

      resolve(&Resolvers.Documents.get/2)
    end

    @desc "get a list of document template categories by type"
    field :document_template_categories_by_type, list_of(:document_template_category) do
      arg(:entity_type, non_null(:string))

      resolve(&Resolvers.Documents.categories_by_type/2)
    end

    # These next 2 are individual fields as the urls expire and thus need to be fetched on demand.
    @desc "get a docusign signing url"
    field :docusign_signing_url, :string do
      arg(:document_id, non_null(:id))
      arg(:redirect_uri, non_null(:string))
      resolve(&Resolvers.Documents.docusign_signing_url/2)
    end

    @desc "get a docusign viewing url for recipient"
    field :docusign_recipient_view_url, :string do
      arg(:document_id, non_null(:id))
      arg(:redirect_uri, non_null(:string))
      resolve(&Resolvers.Documents.docusign_recipient_view_url/2)
    end

    # Clients
    @desc "get a client"
    field :client, :client do
      arg(:id, non_null(:id))
      resolve(&Resolvers.Clients.get/2)
    end

    @desc "get a client by name"
    field :client_for_name, :client do
      arg(:name, non_null(:string))
      resolve(&Resolvers.Clients.get_for_name/2)
    end

    # Partners
    @desc "get a partner"
    field :partner, :partner do
      arg(:id, non_null(:id))
      resolve(&Resolvers.Partners.get/2)
    end

    # Jobs
    @desc "get a job (literally)"
    field :job, :job do
      arg(:id, non_null(:id))
      resolve(&Resolvers.Jobs.get/2)
    end

    # Contracts
    @desc "get a contract"
    field :contract, :contract do
      arg(:id, non_null(:id))
      resolve(&Resolvers.Contracts.get/2)
    end

    @desc "get a client contract"
    field :client_contract, :contract do
      arg(:client_id, non_null(:id))
      resolve(&Resolvers.Contracts.get_for_client/2)
    end

    # Client Managers
    @desc "get a client manager"
    field :client_manager, :client_manager do
      arg(:id, non_null(:id))
      resolve(&Resolvers.ClientManagers.get/2)
    end

    @desc "get paged client managers"
    field :paginated_client_managers_report, :paginated_client_managers_report do
      arg(:page_size, :integer)
      arg(:sort_column, :string)
      arg(:sort_direction, :string)
      arg(:last_id, :id, default_value: 0)
      arg(:last_value, :string, default_value: "")
      arg(:filter_by, list_of(:filter_by), default_value: [])
      arg(:search_by, :string, default_value: "")
      resolve(&Resolvers.ClientManagers.paginated_client_managers_report/2)
    end

    # Partner Managers
    @desc "get a partner manager"
    field :partner_manager, :partner_manager do
      arg(:id, non_null(:id))
      resolve(&Resolvers.PartnerManagers.get/2)
    end

    @desc "get paged partner managers"
    field :paginated_partner_managers_report, :paginated_partner_managers_report do
      arg(:page_size, :integer)
      arg(:sort_column, :string)
      arg(:sort_direction, :string)
      arg(:last_id, :id, default_value: 0)
      arg(:last_value, :string, default_value: "")
      arg(:filter_by, list_of(:filter_by), default_value: [])
      arg(:search_by, :string, default_value: "")
      resolve(&Resolvers.PartnerManagers.paginated_partner_managers_report/2)
    end

    @desc "get an internal employee"
    field :internal_employee, :internal_employee do
      arg(:id, non_null(:id))
      resolve(&Resolvers.InternalEmployees.get/2)
    end

    @desc "get paged internal employees"
    field :paginated_internal_employees_report, :paginated_internal_employees_report do
      arg(:page_size, :integer)
      arg(:sort_column, :string)
      arg(:sort_direction, :string)
      arg(:last_id, :id, default_value: 0)
      arg(:last_value, :string, default_value: "")
      arg(:filter_by, list_of(:filter_by), default_value: [])
      arg(:search_by, :string, default_value: "")
      resolve(&Resolvers.InternalEmployees.paginated_internal_employees_report/2)
    end

    # Employees
    @desc "get an employee"
    field :employee, :employee do
      arg(:id, :id)
      arg(:user_id, :id)
      resolve(&Resolvers.Employees.get/2)
    end

    # Employments
    @desc "get an employment"
    field :employment, :employment do
      arg(:id, non_null(:id))
      resolve(&Resolvers.Employments.get/2)
    end

    # Employments to Client Managers
    @desc "get a client manager to employment association"
    field :employment_client_manager, :employment_client_manager do
      arg(:id, non_null(:id))
      resolve(&Resolvers.EmploymentClientManagers.get/2)
    end

    @desc "get paged employees"
    field :paginated_employees_report, :paginated_employees_report do
      arg(:page_size, :integer)
      arg(:sort_column, :string)
      arg(:sort_direction, :string)
      arg(:last_id, :id, default_value: 0)
      arg(:last_value, :string, default_value: "")
      arg(:filter_by, list_of(:filter_by), default_value: [])
      arg(:search_by, :string, default_value: "")
      resolve(&Resolvers.Employees.paginated_employees_report/2)
    end

    # Regions
    @desc "get a region"
    field :region, :region do
      arg(:id, non_null(:id))
      resolve(&Resolvers.Regions.get/2)
    end

    # PTO Types
    @desc "get a pto type"
    field :pto_type, :pto_type do
      arg(:id, non_null(:id))
      resolve(&Pto.PtoTypes.get/2)
    end

    # PTO Requests
    @desc "get a pto request"
    field :pto_request, :pto_request do
      arg(:id, non_null(:id))
      resolve(&Pto.PtoRequests.get/2)
    end

    @desc "get all pto requests for the current user"
    field :current_user_pto_requests, list_of(:pto_request) do
      resolve(&Pto.PtoRequests.get_for_current_user/2)
    end

    # PTO Request Days
    @desc "get a pto request day"
    field :pto_request_day, :pto_request_day do
      arg(:id, non_null(:id))
      resolve(&Pto.PtoRequestDays.get/2)
    end

    # Employee Onboardings
    @desc "get an employee onboarding"
    field :employee_onboarding, :employee_onboarding do
      arg(:id, non_null(:id))
      resolve(&Resolvers.EmployeeOnboardings.get/2)
    end

    @desc "get all employee onboardings"
    field :employee_onboardings, :paginated_employee_onboardings do
      arg(:page_size, :integer)
      arg(:sort_column, :string)
      arg(:sort_direction, :string)
      arg(:last_id, :id, default_value: 0)
      arg(:last_value, :string, default_value: "")
      arg(:filter_by, list_of(:filter_by), default_value: [])
      arg(:search_by, :string, default_value: "")
      resolve(&Resolvers.EmployeeOnboardings.employee_onboardings/2)
    end

    # Client Onboardings
    @desc "get a client onboarding"
    field :client_onboarding, :client_onboarding do
      arg(:id, :id)
      resolve(&Resolvers.ClientOnboardings.get/2)
    end

    @desc "get a client onboarding for a contract"
    field :client_onboarding_for_contract, :client_onboarding do
      arg(:contract_id, :id)
      resolve(&Resolvers.ClientOnboardings.get_for_contract/2)
    end

    @desc "get all client onboardings"
    field :client_onboardings, :paginated_client_onboardings do
      arg(:page_size, :integer)
      arg(:sort_column, :string)
      arg(:sort_direction, :string)
      arg(:last_id, :id, default_value: 0)
      arg(:last_value, :string, default_value: "")
      arg(:filter_by, list_of(:filter_by), default_value: [])
      arg(:search_by, :string, default_value: "")
      resolve(&Resolvers.ClientOnboardings.client_onboardings/2)
    end

    # Client Companies
    @desc "get paged client companies"
    field :paginated_clients_report, :paginated_clients_report do
      arg(:page_size, :integer)
      arg(:sort_column, :string)
      arg(:sort_direction, :string)
      arg(:last_id, :id, default_value: 0)
      arg(:last_value, :string, default_value: "")
      arg(:filter_by, list_of(:filter_by), default_value: [])
      arg(:search_by, :string, default_value: "")
      resolve(&Resolvers.Clients.paginated_clients_report/2)
    end

    @desc "get profile of a client company"
    field :client_profile, :client do
      arg(:id, non_null(:id))
      resolve(&Resolvers.Clients.get/2)
    end

    @desc "get all teams of a client company"
    field :client_teams, list_of(:team) do
      arg(:client_id, non_null(:id))
      resolve(&Resolvers.Clients.get_teams/2)
    end

    # Services
    field :services, list_of(:service) do
      resolve(&Resolvers.Services.all/2)
    end

    # Process Templates
    field :process_templates, list_of(:process_template) do
      resolve(&Resolvers.ProcessTemplates.all/2)
    end

    # Partner Companies
    @desc "get paged partner companies"
    field :paginated_partners_report, :paginated_partners_report do
      arg(:page_size, :integer)
      arg(:sort_column, :string)
      arg(:sort_direction, :string)
      arg(:last_id, :id, default_value: 0)
      arg(:last_value, :string, default_value: "")
      arg(:filter_by, list_of(:filter_by), default_value: [])
      arg(:search_by, :string, default_value: "")
      resolve(&Resolvers.Partners.paginated_partners_report/2)
    end
  end

  mutation do
    # Current User
    @desc "change language settings for the cuprrent user"
    field :change_user_language, :user do
      arg(:language, non_null(:string))
      resolve(&Resolvers.CurrentUser.change_user_language/2)
    end

    @desc "set client state for the current user"
    field :set_client_state, :user do
      arg(:client_state, non_null(:json))
      resolve(&Resolvers.CurrentUser.set_client_state/2)
    end

    # Forms
    @desc "Save values for one or many forms for the current user"
    field :save_form_values_for_current_user, list_of(:form_field) do
      arg(:field_values, list_of(:form_field_value))

      resolve(&Resolvers.Forms.save_field_values_for_current_user/2)
    end

    @desc "Save values for one or many forms for a passed in user"
    field :save_form_values_for_user, list_of(:form_field) do
      arg(:field_values, list_of(:form_field_value))
      arg(:user_id, non_null(:id))

      resolve(&Resolvers.Forms.save_field_values_for_user/2)
    end

    # Process/Tasks
    @desc "create a process instance"
    field :process, type: :process do
      arg(:process_template_id, non_null(:integer))
      arg(:service_ids, non_null(list_of(:integer)))

      resolve(&Resolvers.Processes.create/2)
    end

    @desc "create a process instance for a template name and service names"
    field :process_for_template_name, type: :process do
      arg(:process_template_name, non_null(:string))
      arg(:service_names, non_null(list_of(:string)))

      resolve(&Resolvers.Processes.create_for_template_name/2)
    end

    @desc "add services to process"
    field :add_process_services, :process do
      arg(:process_id, non_null(:id))
      arg(:service_ids, non_null(list_of(:id)))
      resolve(&Resolvers.Processes.add_services/2)
    end

    @desc "remove services from process"
    field :remove_process_services, :process do
      arg(:process_id, non_null(:id))
      arg(:service_ids, non_null(list_of(:id)))
      resolve(&Resolvers.Processes.remove_services/2)
    end

    @desc "assign user to task"
    field :task_assignment, type: :task do
      arg(:user_id, non_null(:integer))
      arg(:task_id, non_null(:integer))
      arg(:role_id, non_null(:integer))

      resolve(&Resolvers.Tasks.assign/2)
    end

    @desc "add a comment to task"
    field :add_task_comment, type: :task do
      arg(:task_id, non_null(:integer))
      arg(:comment, non_null(:string))
      arg(:visibility_type, non_null(:string))

      resolve(&Resolvers.Tasks.add_comment/2)
    end

    @desc "delete a task comment"
    field :delete_task_comment, type: :task do
      arg(:id, non_null(:id))

      resolve(&Resolvers.Tasks.delete_comment/2)
    end

    @desc """
      updates the status field of the task
    """
    field :update_task_status, type: :task do
      arg(:task_id, non_null(:id))
      arg(:status, non_null(:string))

      resolve(&Resolvers.Tasks.update_status/2)
    end

    @desc "add one or more process role users"
    field :add_process_role_users, type: :process do
      arg(:process_id, non_null(:id))
      arg(:role_id, non_null(:id))
      arg(:user_ids, non_null(list_of(:id)))

      resolve(&Resolvers.Processes.add_process_role_users/2)
    end

    @desc "remove one or more process role users"
    field :remove_process_role_users, type: :process do
      arg(:process_id, non_null(:id))
      arg(:role_id, non_null(:id))
      arg(:user_ids, non_null(list_of(:id)))

      resolve(&Resolvers.Processes.remove_process_role_users/2)
    end

    # PTO
    @desc "simulate the PTO process between a period of time"
    field :simulate_pto, list_of(:pto_ledger) do
      arg(:start_date, :date)
      arg(:end_date, :date)
      arg(:user, :input_user)
      arg(:accrual_policy, :input_pto_accrual_policy)
      arg(:taken_events, list_of(:input_taken_event))
      arg(:manual_events, list_of(:input_manual_adjustment_event))
      arg(:withdrawn_events, list_of(:input_withdrawn_event))
      arg(:persist, :boolean)

      resolve(&Resolvers.Pto.simulate/2)
    end

    # Time Tracking
    @desc "create a time entry"
    field :create_time_entry, type: :time_entry do
      arg(:event_date, non_null(:date))
      arg(:total_hours, non_null(:float))
      arg(:description, :string)
      arg(:time_type_id, non_null(:id))
      arg(:employment_id, :id)

      resolve(&Resolvers.TimeTrackers.create_time_entry/2)
    end

    @desc "delete a time entry"
    field :delete_time_entry, type: :time_entry do
      arg(:id, non_null(:id))

      resolve(&Resolvers.TimeTrackers.delete_time_entry/2)
    end

    @desc "edit a time entry"
    field :edit_time_entry, type: :time_entry do
      arg(:id, non_null(:id))
      arg(:total_hours, :float)
      arg(:description, :string)
      arg(:time_type_id, :id)

      resolve(&Resolvers.TimeTrackers.edit_time_entry/2)
    end

    # Training
    @desc "create a training entry"
    field :create_training, type: :training do
      arg(:name, non_null(:string))
      arg(:description, :string)
      arg(:bundle_url, non_null(:string))

      resolve(&Trainings.create_training/2)
    end

    @desc "update a training entry"
    field :update_training, type: :training do
      arg(:id, non_null(:id))
      arg(:name, non_null(:string))
      arg(:description, :string)
      arg(:bundle_url, non_null(:string))

      resolve(&Trainings.update_training/2)
    end

    @desc "delete a training entry"
    field :delete_training, type: :training do
      arg(:id, non_null(:id))

      resolve(&Trainings.delete_training/2)
    end

    @desc "create an employee training entry"
    field :create_employee_training, type: :employee_training do
      arg(:training_id, non_null(:id))
      arg(:user_id, non_null(:id))
      arg(:status, non_null(:string))
      arg(:due_date, :date)

      resolve(&EmployeeTrainings.create_employee_training/2)
    end

    @desc "update an employee training entry"
    field :update_employee_training, type: :employee_training do
      arg(:id, non_null(:id))
      arg(:training_id, non_null(:id))
      arg(:user_id, non_null(:id))
      arg(:due_date, :date)
      arg(:status, non_null(:string))
      arg(:completed_date, :date)

      resolve(&EmployeeTrainings.update_employee_training/2)
    end

    @desc "delete an employee training entry"
    field :delete_employee_training, type: :employee_training do
      arg(:id, non_null(:id))

      resolve(&EmployeeTrainings.delete_employee_training/2)
    end

    @desc "upserts a document template"
    field :document_template, :document_template do
      arg(:id, :id)
      arg(:name, :string)
      arg(:file_type, :string)
      arg(:action, :string)
      arg(:client_id, :id)
      arg(:partner_id, :id)
      arg(:country_id, :id)
      arg(:document_template_category_id, non_null(:id))
      arg(:required, :boolean)
      arg(:example_file_url, :id)
      arg(:example_filename, :string)
      arg(:example_file_mime_type, :string)

      resolve(&Resolvers.Documents.upsert_document_template/2)
    end

    field :document_template_upload, :s3_upload do
      resolve(&Resolvers.Documents.document_template_upload/2)
    end

    # Documents
    @desc "Update user document metadata"
    field :save_user_document, type: :document do
      arg(:document_id, non_null(:id))
      arg(:s3_key, :id)
      arg(:original_filename, :string)
      arg(:original_mime_type, :string)
      arg(:file_type, :string)
      arg(:status, :string)
      arg(:docusign_template_id, :string)

      resolve(&Resolvers.Documents.save_user_document/2)
    end

    @desc "Update client document metadata"
    field :save_client_document, type: :document do
      arg(:document_id, non_null(:id))
      arg(:s3_key, :id)
      arg(:original_filename, :string)
      arg(:original_mime_type, :string)
      arg(:file_type, :string)
      arg(:status, :string)
      arg(:docusign_template_id, :string)

      resolve(&Resolvers.Documents.save_client_document/2)
    end

    field :delete_document_template, :document_template do
      arg(:id, non_null(:id))

      resolve(&Resolvers.Documents.delete_document_template/2)
    end

    @desc "Create multiple user documents"
    field :create_user_documents, type: list_of(:document) do
      arg(:documents, non_null(list_of(:input_document)))
      arg(:user_id, non_null(:id))

      resolve(&Resolvers.Documents.create_user_documents/2)
    end

    @desc "Create multiple client documents"
    field :create_client_documents, type: list_of(:document) do
      arg(:documents, non_null(list_of(:input_document)))
      arg(:client_id, non_null(:id))

      resolve(&Resolvers.Documents.create_client_documents/2)
    end

    @desc "Create multiple anonymous documents"
    field :create_anonymous_documents, type: list_of(:document) do
      arg(:documents, non_null(list_of(:input_document)))

      resolve(&Resolvers.Documents.create_anonymous_documents/2)
    end

    @desc "Update metadata for multiple user documents"
    field :save_user_documents, type: list_of(:document) do
      arg(:documents, non_null(list_of(:input_document)))
      arg(:user_id, non_null(:id))

      resolve(&Resolvers.Documents.save_user_documents/2)
    end

    @desc "Update metadata for multiple client documents"
    field :save_client_documents, type: list_of(:document) do
      arg(:documents, non_null(list_of(:input_document)))

      resolve(&Resolvers.Documents.save_client_documents/2)
    end

    @desc "delete a user document"
    field :delete_user_document, :document do
      arg(:id, non_null(:id))

      resolve(&Resolvers.Documents.delete_user_document/2)
    end

    @desc "delete a client document"
    field :delete_client_document, :document do
      arg(:id, non_null(:id))

      resolve(&Resolvers.Documents.delete_client_document/2)
    end

    # Clients
    @desc "create a client"
    field :create_client, :client do
      arg(:name, non_null(:string))
      arg(:timezone, :string)
      arg(:segment, :string)
      arg(:industry_vertical, :string)
      arg(:international_market_operating_experience, :string)
      arg(:other_peo_experience, :string)
      arg(:expansion_goals, :string)
      arg(:previous_solutions, :string)
      arg(:goals_and_expectations, :string)
      arg(:pain_points_and_challenges, :string)
      arg(:special_onboarding_instructions, :string)
      arg(:interaction_highlights, :string)
      arg(:interaction_challenges, :string)
      arg(:partner_referral, :string)
      arg(:partner_stakeholder, :string)
      arg(:other_referral_information, :string)
      arg(:standard_payment_terms, :string)
      arg(:payment_type, :string)
      arg(:pricing_structure, :string)
      arg(:pricing_notes, :string)
      arg(:salesforce_id, :string)
      arg(:netsuite_id, :string)
      arg(:pega_pk, :string)
      arg(:pega_ak, :string)
      resolve(&Resolvers.Clients.create_client/2)
    end

    @desc "update a client"
    field :update_client, :client do
      arg(:id, non_null(:id))
      arg(:name, :string)
      arg(:timezone, :string)
      arg(:operational_tier, :string)
      resolve(&Resolvers.Clients.update_client/2)
    end

    @desc "start a client onboarding (from salesforce payload)"
    field :start_client_onboarding, type: :client do
      arg(:client_name, non_null(:string))
      arg(:salesforce_id, non_null(:string))
      arg(:process_template_name, non_null(:string))
      arg(:service_names, non_null(list_of(:string)))
      resolve(&Resolvers.ClientOnboardings.start/2)
    end

    # Partners
    @desc "create a partner instance"
    field :create_partner, type: :partner do
      arg(:address_id, :id)
      arg(:name, non_null(:string))
      arg(:netsuite_id, :string)
      arg(:statement_of_work_with, :string)
      arg(:deployment_agreement_with, :string)
      arg(:contact_guidelines, :string)
      resolve(&Resolvers.Partners.create/2)
    end

    @desc "update a partner"
    field :update_partner, type: :partner do
      arg(:id, non_null(:id))
      arg(:address_id, :integer)
      arg(:name, :string)
      arg(:netsuite_id, :string)
      arg(:statement_of_work_with, :string)
      arg(:deployment_agreement_with, :string)
      arg(:contact_guidelines, :string)
      resolve(&Resolvers.Partners.update/2)
    end

    @desc "delete a partner"
    field :delete_partner, type: :partner do
      arg(:id, non_null(:id))
      resolve(&Resolvers.Partners.delete/2)
    end

    # Partner operating countries
    @desc "create a partner operating country"
    field :create_partner_operating_country, type: :partner_operating_country do
      arg(:partner_id, non_null(:id))
      arg(:country_id, non_null(:id))
      arg(:primary_service, :string)
      arg(:secondary_service, :string)
      arg(:bank_charges, :string)
      resolve(&Resolvers.PartnerOperatingCountries.create_partner_operating_country/2)
    end

    @desc "update a partner operating country"
    field :update_partner_operating_country, type: :partner_operating_country do
      arg(:id, non_null(:id))
      arg(:country_id, :id)
      arg(:primary_service, :string)
      arg(:secondary_service, :string)
      arg(:bank_charges, :string)
      arg(:service_id, :id)
      arg(:fee, :float)
      arg(:fee_type, :string)
      arg(:has_setup_fee, :boolean)
      arg(:observation, :string)
      arg(:setup_fee, :float)
      resolve(&Resolvers.PartnerOperatingCountries.update_partner_operating_country/2)
    end

    @desc "delete a partner operating country"
    field :delete_partner_operating_country, type: :partner_operating_country do
      arg(:id, non_null(:id))
      resolve(&Resolvers.PartnerOperatingCountries.delete_partner_operating_country/2)
    end

    # Jobs
    @desc "create a job instance"
    field :create_job, type: :job do
      arg(:client_id, non_null(:id))
      arg(:title, non_null(:string))
      resolve(&Resolvers.Jobs.create/2)
    end

    @desc "update a job"
    field :update_job, type: :job do
      arg(:id, non_null(:id))
      arg(:title, :string)
      arg(:probationary_period_length, :float)
      arg(:probationary_period_term, :string)
      resolve(&Resolvers.Jobs.update/2)
    end

    @desc "delete a job"
    field :delete_job, type: :job do
      arg(:id, non_null(:id))
      resolve(&Resolvers.Jobs.delete/2)
    end

    # Contracts
    @desc "create a contract instance"
    field :create_contract, type: :contract do
      arg(:client_id, non_null(:id))
      resolve(&Resolvers.Contracts.create/2)
    end

    @desc "update a contract"
    field :update_contract, type: :contract do
      arg(:id, non_null(:id))
      arg(:uuid, :string)
      arg(:payroll_13th_month, :string)
      arg(:payroll_14th_month, :string)
      arg(:termination_date, :date)
      arg(:termination_reason, :string)
      arg(:termination_sub_reason, :string)

      resolve(&Resolvers.Contracts.update/2)
    end

    @desc "delete a contract"
    field :delete_contract, type: :contract do
      arg(:id, non_null(:id))
      resolve(&Resolvers.Contracts.delete/2)
    end

    # Client Managers
    @desc "create a client manager instance"
    field :create_client_manager, type: :client_manager do
      arg(:first_name, non_null(:string))
      arg(:last_name, :string)
      arg(:email, non_null(:string))
      arg(:client_id, non_null(:id))
      arg(:job_title, :string)
      arg(:reports_to_id, :id)

      resolve(&Resolvers.ClientManagers.create/2)
    end

    @desc "update a client manager"
    field :update_client_manager, type: :client_manager do
      arg(:id, non_null(:id))
      arg(:job_title, :string)
      arg(:email, :string)
      arg(:client_id, :id)
      arg(:reports_to_id, :id)
      arg(:first_name, :string)
      arg(:last_name, :string)
      arg(:timezone, :string)
      resolve(&Resolvers.ClientManagers.update_client_manager/2)
    end

    @desc "delete a client manager"
    field :delete_client_manager, type: :client_manager do
      arg(:id, non_null(:id))
      resolve(&Resolvers.ClientManagers.delete/2)
    end

    # Partner managers
    @desc "create a partner manager"
    field :create_partner_manager, type: :partner_manager do
      arg(:first_name, non_null(:string))
      arg(:last_name, :string)
      arg(:email, non_null(:string))
      arg(:partner_id, non_null(:id))
      arg(:job_title, :string)

      resolve(&Resolvers.PartnerManagers.create/2)
    end

    @desc "update a partner manager information"
    field :update_partner_manager, type: :partner_manager do
      arg(:id, non_null(:id))
      arg(:job_title, :string)
      arg(:email, :string)
      arg(:partner_id, :id)
      arg(:first_name, :string)
      arg(:last_name, :string)
      arg(:timezone, :string)
      resolve(&Resolvers.PartnerManagers.update_partner_manager/2)
    end

    @desc "delete a partner manager"
    field :delete_partner_manager, type: :partner_manager do
      arg(:id, non_null(:id))
      resolve(&Resolvers.PartnerManagers.delete/2)
    end

    # Internal Users
    @desc "create an internal employee"
    field :create_internal_employeee, type: :internal_employee do
      arg(:first_name, non_null(:string))
      arg(:last_name, :string)
      arg(:email, non_null(:string))
      arg(:job_title, :string)
      arg(:timezone, :string)
      arg(:role_ids, non_null(:string))

      resolve(&Resolvers.InternalEmployees.create/2)
    end

    @desc "update an internal employee"
    field :update_internal_employee, type: :internal_employee do
      arg(:id, non_null(:id))
      arg(:job_title, :string)
      arg(:email, :string)
      arg(:first_name, :string)
      arg(:last_name, :string)
      arg(:timezone, :string)
      resolve(&Resolvers.InternalEmployees.update/2)
    end

    @desc "assign a role to an internal employee"
    field :assign_role_to_internal_employee, type: :boolean do
      arg(:id, non_null(:id))
      arg(:role_id, non_null(:id))
      arg(:assign, :boolean)
      resolve(&Resolvers.InternalEmployees.assign_role/2)
    end

    # Employees
    @desc "create an employee instance"
    field :create_employee, type: :employee do
      arg(:user_id, non_null(:id))
      resolve(&Resolvers.Employees.create/2)
    end

    @desc "update an employee"
    field :update_employee, type: :employee do
      arg(:id, non_null(:id))
      resolve(&Resolvers.Employees.update/2)
    end

    @desc "delete an employee"
    field :delete_employee, type: :employee do
      arg(:id, non_null(:id))
      resolve(&Resolvers.Employees.delete/2)
    end

    # Employments
    @desc "create an employment instance"
    field :create_employment, type: :employment do
      arg(:partner_id, non_null(:id))
      arg(:employee_id, non_null(:id))
      arg(:job_id, non_null(:id))
      arg(:contract_id, non_null(:id))
      arg(:country_id, non_null(:id))
      arg(:effective_date, non_null(:date))
      resolve(&Resolvers.Employments.create/2)
    end

    @desc "update an employment"
    field :update_employment, type: :employment do
      arg(:id, non_null(:id))
      arg(:employee_id, :id)
      arg(:job_id, :id)
      arg(:contract_id, :id)
      arg(:country_id, :id)
      arg(:effective_date, :date)
      arg(:type, :string)
      arg(:status, :string)
      resolve(&Resolvers.Employments.update/2)
    end

    @desc "delete an employment"
    field :delete_employment, type: :employment do
      arg(:id, non_null(:id))
      resolve(&Resolvers.Employments.delete/2)
    end

    # Employments to Client Managers
    @desc "create an employment to client manager instance"
    field :create_employment_client_manager, type: :employment_client_manager do
      arg(:employment_id, non_null(:id))
      arg(:client_manager_id, non_null(:id))
      arg(:effective_date, non_null(:date))
      resolve(&Resolvers.EmploymentClientManagers.create/2)
    end

    @desc "update an employment to client manager instance"
    field :update_employment_client_manager, type: :employment_client_manager do
      arg(:id, non_null(:id))
      arg(:employment_id, :id)
      arg(:client_manager_id, :id)
      arg(:effective_date, :date)
      resolve(&Resolvers.EmploymentClientManagers.update/2)
    end

    @desc "delete a employment to client manager instance"
    field :delete_employment_client_manager, type: :employment_client_manager do
      arg(:id, non_null(:id))
      resolve(&Resolvers.EmploymentClientManagers.delete/2)
    end

    # Regions
    @desc "create a region instance"
    field :create_region, type: :region do
      arg(:name, non_null(:string))
      resolve(&Resolvers.Regions.create/2)
    end

    @desc "update a region"
    field :update_region, type: :region do
      arg(:id, non_null(:id))
      arg(:name, :string)
      resolve(&Resolvers.Regions.update/2)
    end

    @desc "delete a region"
    field :delete_region, type: :region do
      arg(:id, non_null(:id))
      resolve(&Resolvers.Regions.delete/2)
    end

    # PTO Types
    @desc "create a pto_type instance"
    field :create_pto_type, type: :pto_type do
      arg(:name, non_null(:string))
      resolve(&Pto.PtoTypes.create/2)
    end

    @desc "update a pto_type"
    field :update_pto_type, type: :pto_type do
      arg(:id, non_null(:id))
      arg(:name, :string)
      resolve(&Pto.PtoTypes.update/2)
    end

    @desc "delete a pto_type"
    field :delete_pto_type, type: :pto_type do
      arg(:id, non_null(:id))
      resolve(&Pto.PtoTypes.delete/2)
    end

    # PTO Request
    @desc "create a pto_request with pto_request_days"
    field :create_pto_request_with_days, type: :pto_request do
      arg(:user_id, non_null(:id))
      arg(:accrual_policy_id, non_null(:id))
      arg(:request_comment, :string)
      arg(:pto_type_id, non_null(:id))
      arg(:pto_request_days, non_null(list_of(:input_pto_request_day)))
      resolve(&Pto.PtoRequests.create_with_days/2)
    end

    # TODO: below pto request/day mutations are deprecated, but still being used by simulation UI
    @desc "create a pto_request instance"
    field :create_pto_request, type: :pto_request do
      arg(:employment_id, non_null(:id))
      arg(:request_comment, :string)
      resolve(&Pto.PtoRequests.create/2)
    end

    @desc "update a pto_request"
    field :update_pto_request, type: :pto_request do
      arg(:id, non_null(:id))
      arg(:request_comment, :string)
      resolve(&Pto.PtoRequests.update/2)
    end

    @desc "delete a pto_request"
    field :delete_pto_request, type: :pto_request do
      arg(:id, non_null(:id))
      resolve(&Pto.PtoRequests.delete/2)
    end

    # PTO Request Day
    @desc "create a pto_request_day instance"
    field :create_pto_request_day, type: :pto_request_day do
      arg(:pto_request_id, non_null(:id))
      arg(:accrual_policy_id, non_null(:id))
      arg(:level_id, :id)
      arg(:pto_type_id, non_null(:id))
      arg(:day, non_null(:date))
      arg(:slot, non_null(:string))
      arg(:start_time, :time)
      arg(:end_time, :time)
      resolve(&Pto.PtoRequestDays.create/2)
    end

    @desc "update a pto_request_day"
    field :update_pto_request_day, type: :pto_request_day do
      arg(:id, non_null(:id))
      arg(:day, :date)
      arg(:slot, non_null(:string))
      arg(:start_time, :time)
      arg(:end_time, :time)
      resolve(&Pto.PtoRequestDays.update/2)
    end

    @desc "delete a pto_request_day"
    field :delete_pto_request_day, type: :pto_request_day do
      arg(:id, non_null(:id))
      resolve(&Pto.PtoRequestDays.delete/2)
    end

    # Employee Onboarding
    @desc "create an employee onboarding instance"
    field :create_employee_onboarding, type: :employee_onboarding do
      arg(:employment_id, non_null(:id))
      arg(:process_id, non_null(:id))
      arg(:signature_status, :string)
      arg(:immigration, :boolean)
      arg(:benefits, :boolean)
      resolve(&Resolvers.EmployeeOnboardings.create/2)
    end

    @desc "start an employee onboarding (from salesforce payload)"
    field :start_employee_onboarding, type: :employment do
      arg(:client_id, non_null(:id))
      arg(:salesforce_id, non_null(:id))
      arg(:partner, non_null(:string))
      arg(:country_code, non_null(:string))
      arg(:nationality_code, non_null(:string))
      arg(:first_name, non_null(:string))
      arg(:last_name, non_null(:string))
      arg(:email, non_null(:string))
      arg(:job_title, non_null(:string))
      arg(:anticipated_start_date, non_null(:date))
      arg(:process_template_name, non_null(:string))
      arg(:service_names, non_null(list_of(:string)))
      resolve(&Resolvers.EmployeeOnboardings.start/2)
    end

    @desc "update an employee_onboarding"
    field :update_employee_onboarding, type: :employee_onboarding do
      arg(:id, non_null(:id))
      arg(:employment_id, :id)
      arg(:process_id, :id)
      arg(:signature_status, :string)
      arg(:immigration, :boolean)
      arg(:benefits, :boolean)
      resolve(&Resolvers.EmployeeOnboardings.update/2)
    end

    @desc "delete an employee_onboarding"
    field :delete_employee_onboarding, type: :employee_onboarding do
      arg(:id, non_null(:id))
      resolve(&Resolvers.EmployeeOnboardings.delete/2)
    end

    @desc "send an email"
    field :send_email, type: :sent_email do
      arg(:to, non_null(list_of(:email_recipient)))
      arg(:from, non_null(:email_recipient))
      arg(:cc, list_of(:email_recipient))
      arg(:bcc, list_of(:email_recipient))
      arg(:subject, :string)
      arg(:body, :string)
      arg(:description, :string)
      arg(:attachments, list_of(:email_attachment_input))
      arg(:association_type, :string)
      arg(:association_id, :id)

      resolve(&Resolvers.EmailTemplates.send_email/2)
    end

    # Client Onboarding
    @desc "create a client onboarding instance"
    field :create_client_onboarding, type: :client_onboarding do
      arg(:contract_id, non_null(:id))
      arg(:process_id, non_null(:id))
      resolve(&Resolvers.ClientOnboardings.create/2)
    end

    @desc "update a client_onboarding"
    field :update_client_onboarding, type: :client_onboarding do
      arg(:id, non_null(:id))
      arg(:contract_id, :id)
      arg(:process_id, :id)
      resolve(&Resolvers.ClientOnboardings.update/2)
    end

    @desc "delete a client_onboarding"
    field :delete_client_onboarding, type: :client_onboarding do
      arg(:id, non_null(:id))
      resolve(&Resolvers.ClientOnboardings.delete/2)
    end

    @desc "delete an s3 reference on a user document"
    field :delete_user_s3_metadata, :document do
      arg(:id, non_null(:id))
      arg(:status, non_null(:string))

      resolve(&Resolvers.Documents.delete_user_s3_metadata/2)
    end

    @desc "delete an s3 reference on a client document"
    field :delete_client_s3_metadata, :document do
      arg(:id, non_null(:id))
      arg(:status, non_null(:string))

      resolve(&Resolvers.Documents.delete_client_s3_metadata/2)
    end

    @desc "update or insert a client operating country"
    field :upsert_operating_country, :client_operating_country do
      arg(:id, :id)
      arg(:client_id, :id)
      arg(:country_id, :id)
      arg(:probationary_period_length, :string)
      arg(:notice_period_length, :string)
      arg(:private_medical_insurance, :string)
      arg(:other_insurance_offered, :string)
      arg(:annual_leave, :string)
      arg(:sick_leave, :string)
      arg(:standard_additions_deadline, :string)
      arg(:client_on_faster_reimbursement, :boolean)
      arg(:standard_allowances_offered, :string)
      arg(:standard_bonuses_offered, :string)
      arg(:notes, :string)
      resolve(&Resolvers.ClientOperatingCountries.upsert_operating_country/2)
    end

    @desc "delete a client operating country"
    field :delete_operating_country, :client_operating_country do
      arg(:id, non_null(:id))
      resolve(&Resolvers.ClientOperatingCountries.delete_operating_country/2)
    end

    @desc "update or insert a client meeting record"
    field :upsert_client_meeting, :client_meeting do
      arg(:id, :id)
      arg(:client_id, :id)
      arg(:description, :string)
      arg(:meeting_date, :date)
      arg(:notes, :string)
      resolve(&Resolvers.Meetings.upsert_client_meeting/2)
    end

    @desc "delete a client meeting record"
    field :delete_client_meeting, :meeting do
      arg(:id, non_null(:id))
      resolve(&Resolvers.Meetings.delete_client_meeting/2)
    end

    @desc "update or insert a client email record"
    field :upsert_client_sent_email, :client_sent_email do
      arg(:id, :id)
      arg(:client_id, :id)
      arg(:subject, :string)
      arg(:sent_date, :naive_datetime)
      arg(:description, :string)
      arg(:body, :string)
      resolve(&Resolvers.SentEmails.upsert_client_sent_email/2)
    end

    @desc "delete a client email record"
    field :delete_client_sent_email, :client_sent_email do
      arg(:id, non_null(:id))
      resolve(&Resolvers.SentEmails.delete_client_sent_email/2)
    end

    @desc "update the client general"
    field :update_client_general, :client_general do
      arg(:id, :id)
      arg(:segment, :string)
      arg(:industry_vertical, :string)
      arg(:international_market_operating_experience, :string)
      arg(:other_peo_experience, :string)
      resolve(&Resolvers.Clients.update_client_general/2)
    end

    @desc "update the client goals"
    field :update_client_goals, :client_goals do
      arg(:id, :id)
      arg(:expansion_goals, :string)
      arg(:previous_solutions, :string)
      arg(:goals_and_expectations, :string)
      arg(:pain_points_and_challenges, :string)
      arg(:special_onboarding_instructions, :string)
      resolve(&Resolvers.Clients.update_client_goals/2)
    end

    @desc "update the client interaction notes"
    field :update_client_interaction_notes, :client_interaction_notes do
      arg(:id, :id)
      arg(:interaction_highlights, :string)
      arg(:interaction_challenges, :string)
      resolve(&Resolvers.Clients.update_client_interaction_notes/2)
    end

    @desc "update the client referral information"
    field :update_client_referral_information, :client_referral_information do
      arg(:id, :id)
      arg(:partner_referral, :string)
      arg(:partner_stakeholder, :string)
      arg(:other_referral_information, :string)
      resolve(&Resolvers.Clients.update_client_referral_information/2)
    end

    @desc "update the client payments and pricing"
    field :update_client_payments_and_pricing, :client_payments_and_pricing do
      arg(:id, :id)
      arg(:standard_payment_terms, :string)
      arg(:payment_type, :string)
      arg(:pricing_structure, :string)
      arg(:pricing_notes, :string)
      resolve(&Resolvers.Clients.update_client_payments_and_pricing/2)
    end

    # Client Contacts
    @desc "insert or update MPOC of a country that a client operates"
    field :upsert_mpoc, :client_contact do
      arg(:id, :id)
      arg(:client_id, :id)
      arg(:country_id, :id)
      arg(:user_id, :id)
      resolve(&Resolvers.ClientContacts.upsert_mpoc/2)
    end

    @desc "set MPOC of a region that a client operates"
    field :set_region_mpoc, list_of(:client_contact) do
      arg(:client_id, non_null(:id))
      arg(:region_id, non_null(:id))
      arg(:user_id, :id)
      resolve(&Resolvers.ClientContacts.set_region_mpoc/2)
    end

    @desc "set MPOC of a client company"
    field :set_organization_mpoc, list_of(:client_contact) do
      arg(:client_id, non_null(:id))
      arg(:user_id, :id)
      resolve(&Resolvers.ClientContacts.set_organization_mpoc/2)
    end

    @desc "insert a client secondary contact"
    field :insert_secondary_contact, :client_contact do
      arg(:client_id, non_null(:id))
      arg(:user_id, :id)
      arg(:role_id, :id)
      resolve(&Resolvers.ClientContacts.insert_secondary_contact/2)
    end

    @desc "delete a client secondary contact"
    field :delete_secondary_contact, :client_contact do
      arg(:id, non_null(:id))
      resolve(&Resolvers.ClientContacts.delete_secondary_contact/2)
    end

    # Partner Contact
    @desc "insert or update MPOC of a country that a partner operates"
    field :upsert_partner_mpoc, :partner_contact do
      arg(:id, :id)
      arg(:partner_id, :id)
      arg(:country_id, :id)
      arg(:user_id, :id)
      resolve(&Resolvers.PartnerContacts.upsert_partner_mpoc/2)
    end

    @desc "set MPOC of a region that a partner operates"
    field :set_partner_region_mpoc, list_of(:partner_contact) do
      arg(:partner_id, non_null(:id))
      arg(:region_id, non_null(:id))
      arg(:user_id, :id)
      resolve(&Resolvers.PartnerContacts.set_partner_region_mpoc/2)
    end

    @desc "set MPOC of a partner company"
    field :set_partner_organization_mpoc, list_of(:partner_contact) do
      arg(:partner_id, non_null(:id))
      arg(:user_id, :id)
      resolve(&Resolvers.PartnerContacts.set_partner_organization_mpoc/2)
    end

    # Role Assignment
    @desc "update a client manager role"
    field :update_client_manager_role, :role_assignment do
      arg(:id, :id)
      arg(:employment_id, :id)
      arg(:role_id, :id)
      arg(:active, :boolean)
      resolve(&Resolvers.RoleAssignments.update_client_manager_role/2)
    end
  end

  subscription do
    # Process/Tasks
    field :task_updated, :task do
      arg(:process_id, non_null(:id))

      config(fn args, _ ->
        {:ok, topic: args.process_id}
      end)

      trigger(:update_task_status,
        topic: fn task ->
          task.process_id
        end
      )
    end

    # Time Tracking
    field :time_entry_created, :time_entry do
      config(fn _args, _ ->
        {:ok, topic: "time_entries"}
      end)

      trigger(:create_time_entry,
        topic: fn _time_entry ->
          "time_entries"
        end
      )
    end

    field :time_entry_deleted, :time_entry do
      config(fn _args, _ ->
        {:ok, topic: "time_entries"}
      end)

      trigger(:delete_time_entry,
        topic: fn _time_entry ->
          "time_entries"
        end
      )
    end

    field :time_entry_updated, :time_entry do
      config(fn _args, _ ->
        {:ok, topic: "time_entries"}
      end)

      trigger(:edit_time_entry,
        topic: fn _time_entry ->
          "time_entries"
        end
      )
    end

    # Accrual Policies/Levels
    field :create_accrual_policy, :accrual_policy do
      arg(:pto_type_id, non_null(:id))
      arg(:pega_policy_id, non_null(:string))
      arg(:label, non_null(:string))
      arg(:first_accrual_policy, :string)
      arg(:carryover_day, :string)
      arg(:pool, :string)
      resolve(&Pto.AccrualPolicies.create_accrual_policy/2)
    end

    field :update_accrual_policy, :accrual_policy do
      arg(:id, non_null(:id))
      arg(:pto_type_id, :id)
      arg(:pega_policy_id, :string)
      arg(:label, :string)
      arg(:first_accrual_policy, :string)
      arg(:carryover_day, :string)
      arg(:pool, :string)
      resolve(&Pto.AccrualPolicies.update_accrual_policy/2)
    end

    field :delete_accrual_policy, type: :accrual_policy do
      arg(:id, non_null(:id))
      resolve(&Pto.AccrualPolicies.delete_accrual_policy/2)
    end

    field :create_level, :level do
      arg(:accrual_policy_id, non_null(:id))
      arg(:start_date_interval, :integer)
      arg(:start_date_interval_unit, :string)
      arg(:pega_level_id, :string)
      arg(:accrual_amount, :float)
      arg(:accrual_frequency, :float)
      arg(:accrual_period, :string)
      arg(:max_days, :float)
      arg(:carryover_limit_type, :string)
      arg(:carryover_limit, :float)
      arg(:accrual_calculation_month_day, :string)
      arg(:accrual_calculation_week_day, :integer)
      arg(:accrual_calculation_year_month, :string)
      arg(:accrual_calculation_year_day, :integer)
      resolve(&Pto.Levels.create_level/2)
    end

    field :update_level, :level do
      arg(:id, non_null(:id))
      arg(:accrual_policy_id, :id)
      arg(:start_date_interval, :integer)
      arg(:start_date_interval_unit, :string)
      arg(:pega_level_id, :string)
      arg(:accrual_amount, :float)
      arg(:accrual_frequency, :float)
      arg(:accrual_period, :string)
      arg(:max_days, :float)
      arg(:carryover_limit_type, :string)
      arg(:carryover_limit, :float)
      arg(:accrual_calculation_month_day, :string)
      arg(:accrual_calculation_week_day, :integer)
      arg(:accrual_calculation_year_month, :string)
      arg(:accrual_calculation_year_day, :integer)
      resolve(&Pto.Levels.update_level/2)
    end

    field :delete_level, type: :level do
      arg(:id, non_null(:id))
      resolve(&Pto.Levels.delete_level/2)
    end

    field :deactivate_user_policy, type: :user_policy do
      arg(:accrual_policy_id, non_null(:id))
      arg(:user_id, non_null(:id))
      arg(:end_date, :date)
      resolve(&Pto.UserPolicies.deactivate_user_policy/2)
    end
  end
end
