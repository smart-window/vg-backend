defmodule Velocity.Schema.User do
  @moduledoc "schema for users"
  use Ecto.Schema
  import Ecto.Changeset

  alias Velocity.Schema.Address
  alias Velocity.Schema.Client
  alias Velocity.Schema.Country
  alias Velocity.Schema.ProcessRoleUser
  alias Velocity.Schema.Pto.UserPolicy
  alias Velocity.Schema.RoleAssignment
  alias Velocity.Schema.TaskAssignment
  alias Velocity.Schema.TimeEntry
  alias Velocity.Schema.TimePolicy
  alias Velocity.Schema.UserGroup
  alias Velocity.Schema.UserRole
  alias Velocity.Schema.ViewUserPermissions
  alias Velocity.Utils.Dates, as: Utils

  @fields [
    :first_name,
    :last_name,
    :full_name,
    :email,
    :okta_user_uid,
    :avatar_url,
    :timezone,
    :birth_date,
    :gender,
    :marital_status,
    :visa_work_permit_required,
    :start_date,
    :settings,
    :country_specific_fields,
    :preferred_first_name,
    :phone,
    :business_email,
    :personal_email,
    :emergency_contact_name,
    :emergency_contact_relationship,
    :emergency_contact_phone,
    :client_state,
    :nationality_id
  ]
  @required_fields [:email, :okta_user_uid]

  @derive {Jason.Encoder, only: @fields ++ [:id]}

  schema "users" do
    field :first_name, :string
    field :last_name, :string
    field :full_name, :string
    field :email, :string
    field :okta_user_uid, :string
    field :avatar_url, :string
    field :timezone, :string
    field :birth_date, :date
    field :gender, :string
    field :marital_status, :string
    field :visa_work_permit_required, :boolean
    field :start_date, :date
    field :settings, :map
    field :country_specific_fields, :map
    field :preferred_first_name, :string
    field :phone, :string
    field :business_email, :string
    field :personal_email, :string
    field :emergency_contact_name, :string
    field :emergency_contact_relationship, :string
    field :emergency_contact_phone, :string
    field :client_state, :map

    belongs_to :client, Client
    belongs_to :nationality, Country
    belongs_to :personal_address, Address
    belongs_to :work_address, Address

    belongs_to :current_time_policy, TimePolicy
    has_many :time_entries, TimeEntry

    has_many :user_groups, UserGroup
    has_many :groups, through: [:user_groups, :group]

    has_many :user_roles, UserRole
    has_many :roles, through: [:user_roles, :role]

    has_many :permissions, ViewUserPermissions

    has_many :user_policies, UserPolicy
    has_many :accrual_policies, through: [:user_policies, :accrual_policy]

    has_many :task_assignments, TaskAssignment

    has_many :role_assignments, RoleAssignment

    has_many :process_role_users, ProcessRoleUser

    timestamps()
  end

  def build(attrs), do: changeset(%__MODULE__{}, attrs)

  @doc false
  def changeset(changeset, attrs) do
    cleaned_attrs = clean_attrs(attrs)

    changeset
    |> cast(cleaned_attrs, @fields)
    |> validate_required(@required_fields)
  end

  def required_fields do
    @required_fields
  end

  defp clean_attrs(attrs) do
    start_date = Map.get(attrs, "start_date")

    if start_date && not Utils.is_date?(start_date) do
      Map.update(attrs, "start_date", start_date, fn start_date ->
        Utils.parse_pega_date!(start_date)
      end)
    else
      attrs
    end
  end
end
