defmodule Velocity.Contexts.Groups do
  @moduledoc "context for groups"

  alias Velocity.Contexts.Users
  alias Velocity.Repo
  alias Velocity.Schema.Group
  alias Velocity.Schema.User
  alias Velocity.Schema.UserGroup

  def create(params) do
    changeset = Group.changeset(%Group{}, params)

    Repo.insert(changeset)
  end

  def get_by(keyword) do
    Repo.get_by(Group, keyword)
  end

  def add_group_to_user(group = %Group{}, user = %User{}) do
    changeset = UserGroup.changeset(%UserGroup{}, %{group: group, user: user})

    Repo.insert(changeset)
    Users.assign_user_roles_for_group(user, group)
  end

  def all do
    Repo.all(Group)
  end
end
