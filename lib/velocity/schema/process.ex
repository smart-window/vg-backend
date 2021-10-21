defmodule Velocity.Schema.Process do
  @moduledoc """
  A process is a specific instance of a process template.

  For example an onboarding experience for John Doe.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Velocity.Schema.ClientOnboarding
  alias Velocity.Schema.EmployeeOnboarding
  alias Velocity.Schema.ProcessRoleUser
  alias Velocity.Schema.ProcessService
  alias Velocity.Schema.ProcessTemplate
  alias Velocity.Schema.Stage
  alias Velocity.Schema.Task
  alias Velocity.Schema.User

  schema "processes" do
    field :percent_complete, :float
    field :status, :string
    belongs_to :user, User
    belongs_to :process_template, ProcessTemplate

    has_many :stages, Stage
    has_many :tasks, Task
    has_many :process_services, ProcessService
    has_many :services, through: [:process_services, :service]
    has_many :process_role_users, ProcessRoleUser
    has_many :users, through: [:process_role_users, :user]

    has_one :client_onboarding, ClientOnboarding
    has_one :employee_onboarding, EmployeeOnboarding

    timestamps()
  end

  def build(attrs), do: changeset(%__MODULE__{}, attrs)

  @doc false
  def changeset(process, attrs) do
    process
    |> cast(attrs, [:process_template_id, :status, :percent_complete])
    |> validate_required([:process_template_id, :status, :percent_complete])
  end
end
