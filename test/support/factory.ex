defmodule Velocity.Factory do
  @moduledoc """
  ExMachina Factory definitions
  """
  use ExMachina.Ecto, repo: Velocity.Repo

  alias Velocity.Event
  alias Velocity.Schema

  def address_factory do
    %Schema.Address{
      line_1: "123 test lane"
    }
  end

  def client_factory do
    %Schema.Client{}
  end

  def client_contact_factory do
    %Schema.ClientContact{}
  end

  def country_factory do
    %Schema.Country{
      name: sequence(:country_name, &"test-country-#{&1}"),
      iso_alpha_2_code: sequence(:iso_alpha_2_code, &"ABC-#{&1}")
    }
  end

  def group_factory do
    %Schema.Group{
      slug: "admin",
      okta_group_slug: "some_okta_group"
    }
  end

  def role_factory do
    %Schema.Role{
      slug: "PTO Manager"
    }
  end

  def permission_factory do
    %Schema.Permission{}
  end

  def role_assignment_factory do
    %Schema.RoleAssignment{}
  end

  def group_permission_factory do
    %Schema.GroupPermission{}
  end

  def role_permission_factory do
    %Schema.RolePermission{}
  end

  def user_factory(params) do
    first_name = Faker.Person.first_name()
    last_name = Faker.Person.last_name()

    %Schema.User{
      first_name: first_name,
      last_name: last_name,
      full_name: first_name <> " " <> last_name,
      birth_date: NaiveDateTime.utc_now(),
      email: Map.get(params, :email) || sequence(:email, &"email-#{&1}@example.com"),
      okta_user_uid: Map.get(params, :okta_user_uid) || sequence(:okta_user_uid, &"12345-#{&1}"),
      current_time_policy_id: Map.get(params, :current_time_policy_id),
      start_date: Date.from_iso8601!("2018-09-15"),
      avatar_url: Map.get(params, :avatar_url),
      marital_status: Map.get(params, :marital_status),
      work_address_id: Map.get(params, :work_address_id),
      country_specific_fields: Map.get(params, :country_specific_fields)
    }
  end

  def user_group_factory do
    %Schema.UserGroup{}
  end

  def user_role_factory do
    %Schema.UserRole{}
  end

  def user_policy_factory do
    %Schema.Pto.UserPolicy{}
  end

  def accrual_policy_factory do
    %Schema.Pto.AccrualPolicy{
      pega_policy_id: sequence(:email, &"some-policy-id-#{&1}"),
      carryover_day: "first_of_year"
    }
  end

  def level_factory do
    %Schema.Pto.Level{
      accrual_policy: build(:accrual_policy),
      accrual_period: "days",
      accrual_frequency: 1.0,
      accrual_amount: 1.0,
      start_date_interval: 0,
      start_date_interval_unit: "days",
      carryover_limit_type: "unlimited"
    }
  end

  def ledger_factory do
    %Schema.Pto.Ledger{
      user: build(:user),
      accrual_policy: build(:accrual_policy),
      level: build(:level),
      employment: build(:employment),
      event_date: Date.utc_today(),
      event_type: "accrual",
      regular_balance: 0,
      regular_transaction: 0,
      carryover_balance: 0,
      carryover_transaction: 0
    }
  end

  def time_policy_factory do
    %Schema.TimePolicy{
      slug: "default",
      work_week_start: 1,
      work_week_end: 5
    }
  end

  def time_policy_type_factory do
    %Schema.TimePolicyType{
      time_type: build(:time_type)
    }
  end

  def time_type_factory do
    %Schema.TimeType{
      slug: sequence(:slug, &"#{Faker.Superhero.descriptor()}-#{&1}")
    }
  end

  def time_entry_factory do
    %Schema.TimeEntry{
      time_type: build(:time_type)
    }
  end

  def process_factory do
    %Schema.Process{
      process_template: build(:process_template),
      stages: build_list(3, :stage)
    }
  end

  def custom_process_factory do
    %Schema.Process{}
  end

  def stage_factory do
    %Schema.Stage{
      stage_template: build(:stage_template),
      tasks: build_list(3, :task)
    }
  end

  def custom_stage_factory do
    %Schema.Stage{}
  end

  def task_factory do
    %Schema.Task{
      completion_type: "check_off",
      status: "not_started",
      task_template: build(:task_template)
    }
  end

  def custom_task_factory do
    %Schema.Task{}
  end

  def process_template_factory do
    %Schema.ProcessTemplate{
      type: "onboarding",
      stage_templates: build_list(3, :stage_template)
    }
  end

  def custom_process_template_factory do
    %Schema.ProcessTemplate{}
  end

  def stage_template_factory do
    %Schema.StageTemplate{
      name: Faker.Pokemon.name(),
      order: sequence(:stage_template_order, & &1),
      task_templates: build_list(5, :task_template)
    }
  end

  def custom_stage_template_factory do
    %Schema.StageTemplate{}
  end

  def task_template_factory do
    %Schema.TaskTemplate{
      order: sequence(:task_template_order, & &1),
      name: Faker.Pokemon.name(),
      service: build(:service),
      knowledge_article_urls: [Faker.Internet.url()]
    }
  end

  def custom_task_template_factory do
    %Schema.TaskTemplate{}
  end

  def service_factory do
    %Schema.Service{
      name: sequence(:service, &"some-service-#{&1}")
    }
  end

  def process_service_factory do
    %Schema.ProcessService{}
  end

  def task_assignment_factory do
    %Schema.TaskAssignment{
      user: build(:user)
    }
  end

  def dependent_task_template_factory do
    %Schema.DependentTaskTemplate{}
  end

  def notification_template_factory do
    %Schema.NotificationTemplate{
      event: Atom.to_string(Enum.random(Event.events())),
      title: Faker.Team.name(),
      body: Faker.StarWars.quote()
    }
  end

  def notification_default_factory do
    %Schema.NotificationDefault{
      notification_template: build(:notification_template),
      channel: "email",
      minutes_from_event: 0,
      roles: [],
      actors: ["user"],
      user_ids: []
    }
  end

  def custom_notification_default_factory do
    %Schema.NotificationDefault{}
  end

  def user_notification_override_factory do
    %Schema.UserNotificationOverride{
      user: build(:user),
      notification_default: build(:notification_default),
      should_send: false
    }
  end

  def knowledge_article_factory do
    %Schema.KnowledgeArticle{
      url: "wow"
    }
  end

  def dependent_task_factory do
    %Schema.DependentTask{}
  end

  def form_factory do
    %Schema.Form{
      slug: "test form"
    }
  end

  def form_field_factory do
    %Schema.FormField{
      type: "text"
    }
  end

  def form_form_field_factory do
    %Schema.FormFormField{}
  end

  def email_template_factory do
    %Schema.EmailTemplate{
      html_sections: build_list(3, :html_section)
    }
  end

  def html_section_factory do
    country = if :rand.uniform(10) > 8, do: build(:country)

    %Schema.HTMLSection{
      order: sequence(:email_template_order, & &1),
      country: country,
      html: """
        <div class="footer">
          <table role="presentation" border="0" cellpadding="0" cellspacing="0">
            <tr>
              <td class="content-block">
                <span class="apple-link">Company Inc, 3 Abbey Road, San Francisco CA 94102</span>
                <br> Don't like these emails? <a href="http://i.imgur.com/CScmqnj.gif">Unsubscribe</a>.
              </td>
            </tr>
            <tr>
              <td class="content-block powered-by">
                Powered by <a href="http://htmlemail.io">HTMLemail</a>.
              </td>
            </tr>
          </table>
        </div>
      """
    }
  end

  def document_factory do
    %Schema.Document{}
  end

  def user_document_factory do
    %Schema.UserDocument{}
  end

  def client_document_factory do
    %Schema.ClientDocument{}
  end

  def document_template_factory do
    %Schema.DocumentTemplate{}
  end

  def document_template_category_factory do
    %Schema.DocumentTemplateCategory{}
  end

  def partner_factory do
    %Schema.Partner{}
  end

  def partner_operating_country_factory do
    %Schema.PartnerOperatingCountry{}
  end

  def partner_operating_country_service_factory do
    %Schema.PartnerOperatingCountryService{}
  end

  def partner_contact_factory do
    %Schema.PartnerContact{}
  end

  def partner_manager_factory do
    %Schema.PartnerManager{}
  end

  def job_factory do
    %Schema.Job{
      client: build(:client)
    }
  end

  def client_manager_factory do
    %Schema.ClientManager{}
  end

  def contract_factory do
    %Schema.Contract{
      client: build(:client)
    }
  end

  def employee_factory do
    %Schema.Employee{
      user: build(:user)
    }
  end

  def employment_factory do
    %Schema.Employment{
      partner: build(:partner),
      employee: build(:employee),
      job: build(:job),
      contract: build(:contract),
      country: build(:country)
    }
  end

  def employment_client_manager_factory do
    %Schema.EmploymentClientManager{}
  end

  def region_factory do
    %Schema.Region{}
  end

  def pto_type_factory do
    %Schema.Pto.PtoType{
      name: sequence(:pto_type_name, &"#{Faker.Pokemon.name()}-#{&1}")
    }
  end

  def pto_request_factory do
    %Schema.Pto.PtoRequest{
      decision: Enum.random([:approve, :reject, :return, :modify]),
      pto_request_days: build_list(3, :pto_request_day)
    }
  end

  def pto_request_day_factory do
    %Schema.Pto.PtoRequestDay{
      accrual_policy: build(:accrual_policy),
      pto_type: build(:pto_type),
      slot: Enum.random(["afternoon", "morning"]),
      day: ~D[2021-01-15]
    }
  end

  def employee_onboarding_factory do
    %Schema.EmployeeOnboarding{}
  end

  def client_onboarding_factory do
    %Schema.ClientOnboarding{}
  end

  def client_operating_country_factory do
    %Schema.ClientOperatingCountry{
      client: build(:client),
      country: build(:country),
      probationary_period_length: "",
      notice_period_length: "",
      private_medical_insurance: "",
      other_insurance_offered: "",
      annual_leave: "",
      sick_leave: "",
      standard_additions_deadline: "",
      client_on_faster_reimbursement: false,
      standard_allowances_offered: "",
      standard_bonuses_offered: "",
      notes: ""
    }
  end

  def meeting_factory do
    %Schema.Meeting{
      meeting_date: Date.utc_today(),
      description: Faker.Lorem.sentence(5),
      notes: Faker.Lorem.sentence(10)
    }
  end

  def client_meeting_factory do
    %Schema.ClientMeeting{}
  end

  def sent_email_factory do
    %Schema.SentEmail{
      sent_date: NaiveDateTime.utc_now(),
      description: Faker.Lorem.sentence(5),
      body: Faker.Lorem.sentence(10),
      subject: Faker.Lorem.sentence(5)
    }
  end

  def client_sent_email_factory do
    %Schema.ClientSentEmail{}
  end

  def team_factory do
    %Schema.Team{
      name: Faker.Person.name()
    }
  end

  def client_team_factory do
    %Schema.ClientTeam{}
  end

  def training_factory do
    %Schema.Training.Training{}
  end

  def training_country_factory do
    %Schema.Training.TrainingCountry{}
  end

  def person_factory do
    %Schema.Person{}
  end
end
