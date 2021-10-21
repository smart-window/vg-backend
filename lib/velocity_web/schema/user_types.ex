defmodule VelocityWeb.Schema.UserTypes do
  @moduledoc false
  use Absinthe.Schema.Notation

  alias Velocity.Repo
  alias Velocity.Schema.Employee

  @desc "user"
  object :user do
    field :id, :id
    field :full_name, :string
    field :first_name, :string
    field :preferred_first_name, :string
    field :last_name, :string
    field :birth_date, :date
    field :settings, :settings
    field :client_state, :json
    field :avatar_url, :string
    field :timezone, :string

    field :permissions, list_of(:permission) do
      resolve(fn user, _args, _info ->
        user = Repo.preload(user, :permissions)
        {:ok, user.permissions}
      end)
    end

    field(:work_address_country_name, :string) do
      resolve(fn user, _args, _info ->
        user = Repo.preload(user, work_address: :country)

        if is_nil(user.work_address) do
          {:ok, nil}
        else
          {:ok, user.work_address.country.name}
        end
      end)
    end

    field(:nationality, :country) do
      resolve(fn user, _args, _info ->
        country = Ecto.assoc(user, :nationality) |> Repo.one()
        {:ok, country}
      end)
    end

    field(:client, :client) do
      resolve(fn user, _args, _info ->
        client = Ecto.assoc(user, :client) |> Repo.one()
        {:ok, client}
      end)
    end

    field(:employee, :employee) do
      resolve(fn user, _args, _info ->
        employee = Repo.get_by(Employee, user_id: user.id)

        {:ok, employee}
      end)
    end

    field :process_role_users, list_of(:process_role_user)

    field :roles, list_of(:role) do
      resolve(fn user, _args, _info ->
        user = Repo.preload(user, :roles)
        {:ok, user.roles}
      end)
    end

    field :okta_user_uid, :id
    field :email, :string
  end

  input_object :input_user do
    field :okta_user_uid, :id
    field :email, :string
    field :start_date, :date
  end

  object :settings do
    field :language, :string
  end
end
