defmodule VelocityWeb.Schema.ClientManagerTypes do
  @moduledoc false
  use Absinthe.Schema.Notation

  import Ecto.Query

  alias Velocity.Repo
  alias Velocity.Schema.ClientContact
  alias Velocity.Schema.RoleAssignment

  @desc "client_manager"
  object :client_manager do
    field :id, :id
    field :job_title, :string
    field :email, :string

    field(:role_assignments, list_of(:role_assignment)) do
      resolve(fn cm, _args, _info ->
        role_assignments =
          from(ra in RoleAssignment,
            where:
              ra.user_id == ^cm.user_id and ra.client_id == ^cm.client_id and
                not is_nil(ra.employee_id)
          )
          |> Repo.all()

        {:ok, role_assignments}
      end)
    end

    field(:mpocs, list_of(:client_contact)) do
      resolve(fn cm, _args, _info ->
        client_contact =
          ClientContact
          |> where(user_id: ^cm.user_id, client_id: ^cm.client_id, is_primary: true)
          |> Repo.all()

        {:ok, client_contact}
      end)
    end

    field(:reports_to, :client_manager) do
      resolve(fn client_manager, _args, _info ->
        client_manager = Ecto.assoc(client_manager, :reports_to) |> Repo.one()
        {:ok, client_manager}
      end)
    end

    field(:client, :client) do
      resolve(fn client_manager, _args, _info ->
        client = Ecto.assoc(client_manager, :client) |> Repo.one()
        {:ok, client}
      end)
    end

    field(:user, :user) do
      resolve(fn client_manager, _args, _info ->
        user = Ecto.assoc(client_manager, :user) |> Repo.one()
        {:ok, user}
      end)
    end
  end

  object :client_manager_report_item do
    field :id, :id
    field :name, :string
    field :job_title, :string
    field :client_name, :string
    field :region_name, :string
    field :country_name, :string
    field :roles, :string
  end

  object :paginated_client_managers_report do
    field :row_count, :integer
    field :client_manager_report_items, list_of(:client_manager_report_item)
  end
end
