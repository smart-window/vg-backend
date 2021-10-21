defmodule VelocityWeb.Schema.EmployeeTypes do
  @moduledoc false
  use Absinthe.Schema.Notation

  alias Velocity.Repo
  alias Velocity.Schema.Client
  alias Velocity.Schema.Country

  @desc "employee"
  object :employee do
    field :id, :id
    field :user_id, :id
    field :pega_ak, :string

    field(:user, :user) do
      resolve(fn user, _args, _info ->
        user = Ecto.assoc(user, :user) |> Repo.one()
        {:ok, user}
      end)
    end

    field :employments, list_of(:employment) do
      resolve(fn employee, _args, _info ->
        employments = Ecto.assoc(employee, :employments) |> Repo.all()
        {:ok, employments}
      end)
    end
  end

  @desc "employee report item"
  object :employee_report_item do
    field :id, :id
    field :full_name, :string
    field :partner_name, :string
    field :partner_id, :id
    field :client_name, :string
    field :client_id, :id
    field :country_name, :string
    field :country_iso_three, :string
    field :country_short_name, :string, deprecate: true
    field :country_id, :id
    field :region_name, :string
    field :avatar_url, :string
    field :email, :string
    field :phone, :string
    field :title, :string
    field :employment_type, :string

    field(:user, :user) do
      resolve(fn user, _args, _info ->
        user = Ecto.assoc(user, :user) |> Repo.one()
        {:ok, user}
      end)
    end

    # this is temporary until we decide where in the database to store employment status
    field(:status, :string) do
      resolve(fn _user, _args, _info ->
        status = Enum.random(["onboarding", "active", "offboarding"])
        {:ok, status}
      end)
    end

    field(:country, :country) do
      resolve(fn user, _args, _info ->
        country = Repo.get(Country, user.country_id)
        {:ok, country}
      end)
    end

    field(:client, :client) do
      resolve(fn user, _args, _info ->
        client = Repo.get(Client, user.client_id)
        {:ok, client}
      end)
    end
  end

  object :paginated_employees_report do
    field :row_count, :integer
    field :employee_report_items, list_of(:employee_report_item)
  end
end
