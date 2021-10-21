defmodule Velocity.Contexts.Users do
  @moduledoc "context for users"

  alias Velocity.Contexts.Roles
  alias Velocity.Repo
  alias Velocity.Schema.Group
  alias Velocity.Schema.User
  alias Velocity.Schema.UserGroup
  alias Velocity.Schema.UserRole

  import Ecto.Query

  require Logger

  # Mapping of groups to granted roles (there may also be roles un-related to a group)
  @group_slug_to_role_slugs %{
    "csr" => ["employee-reporting"]
  }

  def create(params, opts \\ []) do
    changeset = User.changeset(%User{}, params)

    Repo.insert(changeset, opts)
  end

  def find_or_create(params = %{okta_user_uid: okta_user_uid}, opts \\ []) do
    case get_by(okta_user_uid: okta_user_uid) do
      nil ->
        Logger.info("user with okta_user_uid #{okta_user_uid} not found... will create.")

        create(params, opts)

      user = %User{} ->
        Logger.info("user with okta_user_uid #{okta_user_uid} found... will not create.")
        {:ok, user}
    end
  end

  def delete(keyword) do
    case Repo.get_by(User, keyword) do
      nil ->
        {:ok, :user_not_found}

      user = %User{} ->
        Repo.delete(user)
    end
  end

  def find_by_okta_user_uid(okta_user_uid) do
    case get_by(okta_user_uid: okta_user_uid) do
      user = %User{} ->
        {:ok, user}

      nil ->
        {:error, "no user found for okta_user_uid: " <> okta_user_uid}
    end
  end

  def get_by(keyword) do
    Repo.get_by(User, keyword)
  end

  def assign_user_to_group(user, group, assign_role \\ true) do
    changeset = UserGroup.changeset(%UserGroup{}, %{user: user, group: group})

    Repo.insert(changeset,
      on_conflict: [set: [updated_at: DateTime.utc_now()]],
      conflict_target: [:user_id, :group_id],
      returning: true
    )

    if assign_role == true do
      assign_user_roles_for_group(user, group)
    end
  end

  def remove_user_from_group(user, group) do
    case Repo.get_by(UserGroup, %{user_id: user.id, group_id: group.id}) do
      nil ->
        {:ok, :user_group_not_found}

      user_group = %UserGroup{} ->
        Repo.delete(user_group)
    end

    remove_user_roles_for_group(user, group)
  end

  def assign_roles_to_user_by_id(user, role_ids) do
    inserted_and_updated_at = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    user_roles_params =
      Enum.map(role_ids, fn role_id ->
        %{
          user_id: user.id,
          role_id: role_id,
          inserted_at: inserted_and_updated_at,
          updated_at: inserted_and_updated_at
        }
      end)

    {_num, user_roles} =
      Repo.insert_all(UserRole, user_roles_params,
        on_conflict: :nothing,
        conflict_target: [:user_id, :role_id],
        returning: true
      )

    {:ok, user_roles}
  end

  @doc """
    Based on the above @group_slug_to_role_slugs map,
    assign applicable roles for the corresponding user/group.
  """
  def assign_user_roles_for_group(user, group) do
    all_roles = Roles.all()
    roles_list = Map.get(@group_slug_to_role_slugs, group.slug)
    inserted_and_updated_at = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    if not is_nil(roles_list) do
      user_roles_params =
        Enum.map(roles_list, fn role_slug ->
          role = Enum.find(all_roles, &(&1.slug == role_slug))

          %{
            user_id: user.id,
            role_id: role.id,
            inserted_at: inserted_and_updated_at,
            updated_at: inserted_and_updated_at
          }
        end)

      Repo.insert_all(UserRole, user_roles_params,
        on_conflict: :nothing,
        conflict_target: [:user_id, :role_id]
      )
    end
  end

  @doc """
    Based on the above @group_slug_to_role_slugs map,
    remove applicable roles for the corresponding user/group.
  """
  def remove_user_roles_for_group(user, group) do
    all_roles = Roles.all()
    roles_list = Map.get(@group_slug_to_role_slugs, group.slug) || []

    deletes_successful =
      Enum.reduce(roles_list, true, fn role_slug, is_success ->
        role = Enum.find(all_roles, &(&1.slug == role_slug))

        case Repo.get_by(UserRole, %{user_id: user.id, role_id: role.id}) do
          nil ->
            is_success

          user_role = %UserRole{} ->
            {delete_result, _} = Repo.delete(user_role)
            is_success && delete_result == :ok
        end
      end)

    if deletes_successful do
      {:ok, roles_list}
    else
      {:error, "Error removing UserRoles for group: #{group.slug}"}
    end
  end

  def remove_user_roles_by_id(user, role_ids) do
    deletes_successful =
      Enum.reduce(role_ids, true, fn role_id, is_success ->
        case Repo.get_by(UserRole, %{user_id: user.id, role_id: role_id}) do
          nil ->
            is_success

          user_role = %UserRole{} ->
            {delete_result, _} = Repo.delete(user_role)
            is_success && delete_result == :ok
        end
      end)

    if deletes_successful do
      {:ok}
    else
      {:error}
    end
  end

  def with_group(group_slug) do
    Repo.all(
      from(u in User,
        join: r in assoc(u, :groups),
        where: r.slug == ^group_slug
      )
    )
  end

  def with_role(role_slug) do
    Repo.all(
      from(u in User,
        join: r in assoc(u, :roles),
        where: r.slug == ^role_slug
      )
    )
  end

  def with_id(ids) do
    Repo.all(from(u in User, where: u.id in ^ids))
  end

  def change_user_language(user, language) do
    new_settings = Map.merge(user.settings, %{"language" => language})
    changeset = User.changeset(user, %{settings: new_settings})

    case Repo.update(changeset) do
      {:ok, updated_user} ->
        {:ok, AtomicMap.convert(updated_user, safe: false)}

      error ->
        error
    end
  end

  def update!(user, params) do
    changeset = User.changeset(user, params)
    Repo.update!(changeset)
  end

  def csr_users do
    query =
      from(u in User,
        as: :user,
        join: ug in UserGroup,
        as: :user_group,
        on: u.id == ug.user_id,
        left_join: g in Group,
        as: :group,
        on: ug.group_id == g.id,
        where: g.slug == "csr"
      )

    Repo.all(query)
  end

  def is_user_internal(user) do
    user_with_groups = Repo.preload(user, :groups)

    is_internal =
      Enum.find(user_with_groups.groups, fn group ->
        group.slug == "admin" || group.slug == "csr"
      end)

    if is_internal != nil do
      true
    else
      false
    end
  end
end
