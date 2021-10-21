defmodule VelocityWeb.Resolvers.TimeTrackers do
  @moduledoc """
  GQL resolver for time tracking
  """

  require Logger

  alias Velocity.Contexts.Employments
  # alias Velocity.Contexts.RoleAssignments
  alias Velocity.Contexts.TimeTracking
  alias Velocity.Repo
  alias Velocity.Schema.TimeEntry

  def list_time_entries(args, %{context: %{current_user: current_user}}) do
    time_entries =
      TimeTracking.list_time_entries(
        current_user,
        args.start_date,
        args.end_date
      )

    {:ok, time_entries}
  end

  def get_time_types(_args, %{context: %{current_user: current_user}}) do
    time_policy_id =
      if is_nil(current_user.current_time_policy_id),
        do: TimeTracking.get_time_policy_by(slug: "default").id,
        else: current_user.current_time_policy_id

    time_types = TimeTracking.get_time_types(time_policy_id)

    {:ok, time_types}
  end

  def get_all_time_types(_args, _) do
    time_types = TimeTracking.get_all_time_types()

    {:ok, time_types}
  end

  @doc """
    Creates a time entry with the given time_type, hours, date and description,
    gathering the remaining params from the current_user context.
    ## Parameters
      - args: GQL create time_entry parameters
    ## Returns {:ok, Ecto.Schema.TimeEntry()}
  """
  @spec create_time_entry(map, %{
          context: %{current_user: User.t()}
        }) :: {:ok, any}
  def create_time_entry(args, %{context: %{current_user: current_user}}) do
    time_policy =
      if is_nil(current_user.current_time_policy_id),
        do: TimeTracking.get_time_policy_by(slug: "default"),
        else: TimeTracking.get_time_policy_by(id: current_user.current_time_policy_id)

    employment =
      if Map.has_key?(args, :employment_id) do
        Employments.get_for_user(current_user.id, args.employment_id)
      else
        Employments.get_current_for_user(current_user.id)
      end

    time_entry_params = %{
      event_date: args.event_date,
      description: args.description,
      total_hours: args.total_hours,
      time_policy_id: time_policy.id,
      time_type_id: args.time_type_id,
      employment_id: employment.id,
      user_id: current_user.id
    }

    case TimeTracking.create_time_entry(time_entry_params) do
      {:ok, new_time_entry} ->
        new_time_entry_with_type_and_policy =
          Repo.preload(new_time_entry, [:time_type, :time_policy])

        {:ok, new_time_entry_with_type_and_policy}

      {:error, error} ->
        {:error, error}
    end
  end

  @doc """
    Deletes a time entry with the given id.

    ## Example
      case TimeTrackers.delete_time_entry(%{id: 1}, %{context: %{current_user: %{id: 4}}}) do
        {:ok, struct}       -> # Deleted with success
        {:error, changeset} -> # Something went wrong
      end
  """
  @spec delete_time_entry(
          %{id: String.t()},
          %{context: %{current_user: User.t()}}
        ) :: {:ok, %{}} | {:error, %{}}
  def delete_time_entry(%{id: id}, %{context: %{current_user: _current_user}}) do
    time_entry = Repo.get!(TimeEntry, id)
    Repo.delete(time_entry)
  end

  @doc """
    Edits an existing time entry with new time_type, hours, and description values.
    Gathers the remaining params from the current_user context.
    ## Parameters
      - args: GQL edit time_entry parameters
    ## Returns {:ok, Ecto.Schema.TimeEntry()}
  """
  def edit_time_entry(args, %{context: %{current_user: current_user}}) do
    time_entry_params = %{
      description: args.description,
      total_hours: args.total_hours,
      time_type_id: args.time_type_id,
      user_id: current_user.id
    }

    case TimeTracking.edit_time_entry(args.id, time_entry_params) do
      {:ok, time_entry} ->
        with_time_types = Repo.preload(time_entry, [:time_type])
        {:ok, with_time_types}

      {:error, error} ->
        {:error, error}
    end
  end

  def paged_time_entries(args, %{context: %{current_user: _current_user}}) do
    # role_assignment_type = RoleAssignments.get_assignment_type(current_user, "employee-reporting")

    # if is_nil(role_assignment_type) do
    #   {:error, "insufficient permissions to view time entries report"}
    # else
    # current possiblilities are "global", "external", or nil
    # only_ee_entries = role_assignment_type == "external"
    only_ee_entries = false

    time_entry_report_items =
      TimeTracking.paged_time_entries(
        args.page_size,
        String.to_atom(Macro.underscore(args.sort_column)),
        String.to_atom(args.sort_direction),
        args.last_id,
        args.last_value,
        args.filter_by,
        args.search_by,
        only_ee_entries
      )

    row_count =
      if Enum.count(time_entry_report_items) > 0 do
        Enum.at(time_entry_report_items, 0)[:sql_row_count]
      else
        0
      end

    {:ok, %{row_count: row_count, time_entry_report_items: time_entry_report_items}}
    # end
  end
end
