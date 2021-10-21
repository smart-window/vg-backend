defmodule Velocity.Contexts.Roles do
  @moduledoc "context for roles"

  alias Velocity.Repo
  alias Velocity.Schema.Role
  alias Velocity.Schema.User
  alias Velocity.Schema.UserRole

  @csr_roles [
    "ClientAccountAssociate",
    "ClientAccountManager",
    "ClientFinanceManager",
    "Executive",
    "HRSpecialist",
    "ImmigrationAssociate",
    "ImmigrationManager",
    "NetworkTeam",
    "PayrollTeam",
    "RegionalAccountAssociate",
    "RegionalAccountManager",
    "RegionalDirector",
    "SeniorManager"
  ]

  @client_manager_roles [
    "HRManager",
    "PTOManager"
  ]

  def create(params) do
    changeset = Role.changeset(%Role{}, params)

    Repo.insert(changeset)
  end

  def get_by(keyword) do
    Repo.get_by(Role, keyword)
  end

  def add_role_to_user(role = %Role{}, user = %User{}) do
    changeset = UserRole.changeset(%UserRole{}, %{role: role, user: user})

    Repo.insert(changeset)
  end

  def all do
    Repo.all(Role)
  end

  def csr_roles do
    roles = Repo.all(Role)

    Enum.filter(roles, fn role ->
      Enum.find(@csr_roles, fn slug -> slug == role.slug end)
    end)
  end

  def client_manager_roles do
    roles = Repo.all(Role)

    Enum.filter(roles, fn role ->
      Enum.find(@client_manager_roles, fn slug -> slug == role.slug end)
    end)
  end
end
