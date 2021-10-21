defmodule Mix.Tasks.RemoveGroupPermission do
  @moduledoc """
    Mix Task for removing group_permission entries.

    example usage:
      mix remove_group_permission "training" "customers"
  """
  use Mix.Task

  alias Velocity.Repo
  alias Velocity.Schema.Group
  alias Velocity.Schema.GroupPermission
  alias Velocity.Schema.Permission

  import Ecto.Query

  require Logger

  def run([permission_slug, group_slug]) do
    Application.put_env(:velocity, :minimal, true)
    {:ok, _} = Application.ensure_all_started(:velocity)

    group_permissions_query =
      from(rp in GroupPermission,
        join: p in Permission,
        join: r in Group,
        on:
          p.id == rp.permission_id and
            r.id == rp.group_id,
        where: p.slug == ^permission_slug and r.slug == ^group_slug
      )

    {deleted_row_count, _} = Repo.delete_all(group_permissions_query)
    Logger.info("#{deleted_row_count} group_permission rows deleted")
  end
end
