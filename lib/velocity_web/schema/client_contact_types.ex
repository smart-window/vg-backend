defmodule VelocityWeb.Schema.ClientContactTypes do
  @moduledoc false
  use Absinthe.Schema.Notation

  import Ecto.Query

  alias Velocity.Repo
  alias Velocity.Schema.RoleAssignment

  @desc "client_contacts"
  object :client_contact do
    field :id, :id
    field :is_primary, :boolean
    field :client_id, :id
    field :country_id, :id
    field :user_id, :id

    field(:client, :client) do
      resolve(fn client, _args, _info ->
        client = Ecto.assoc(client, :client) |> Repo.one()
        {:ok, client}
      end)
    end

    field(:user, :user) do
      resolve(fn user, _args, _info ->
        user = Ecto.assoc(user, :user) |> Repo.one()
        {:ok, user}
      end)
    end

    field(:country, :country) do
      resolve(fn country, _args, _info ->
        country = Ecto.assoc(country, :country) |> Repo.one()
        {:ok, country}
      end)
    end

    field(:roles, list_of(:role)) do
      resolve(fn cc, _args, _info ->
        query =
          from(ra in RoleAssignment,
            where:
              ra.user_id == ^cc.user_id and ra.client_id == ^cc.client_id and
                is_nil(ra.employee_id)
          )

        if cc.is_primary == true do
          query =
            from(ra in RoleAssignment,
              where:
                ra.user_id == ^cc.user_id and ra.client_id == ^cc.client_id and
                  not is_nil(ra.employee_id)
            )
        end

        role_assignments =
          query
          |> Repo.all()
          |> Repo.preload(:role)

        {:ok, Enum.map(role_assignments, fn role_assignment -> role_assignment.role end)}
      end)
    end
  end
end
