defmodule VelocityWeb.Schema.TimeTrackingTypes do
  @moduledoc false
  use Absinthe.Schema.Notation

  alias Velocity.Repo

  @desc "time entry"
  object :time_entry do
    field :id, :id
    field :event_date, :date
    field :description, :string
    field :total_hours, :float
    field :user_id, :id
    field :time_type_id, :id
    field :time_policy_id, :id
    field :employment_id, :id
    field :time_policy, :time_policy

    field(:time_type, :time_type) do
      resolve(fn time_entry, _args, _info ->
        time_type = Ecto.assoc(time_entry, :time_type) |> Repo.one()
        {:ok, time_type}
      end)
    end

    field(:user, :user) do
      resolve(fn time_entry, _args, _info ->
        user = Ecto.assoc(time_entry, :user) |> Repo.one()
        {:ok, user}
      end)
    end

    field(:employment, :employment) do
      resolve(fn employment, _args, _info ->
        employment = Ecto.assoc(employment, :employment) |> Repo.one()
        {:ok, employment}
      end)
    end
  end

  @desc "time entry report item"
  object :time_entry_report_item do
    field :id, :id
    field :description, :string
    field :event_date, :date
    field :total_hours, :float
    field :time_type_slug, :string
    field :user_client_name, :string
    field :user_full_name, :string
    field :user_last_name, :string
    field :user_work_address_country_name, :string
  end

  @desc "time type"
  object :time_type do
    field :id, :id
    field :slug, :id
    field :description, :string
  end

  @desc "time policy"
  object :time_policy do
    field :id, :id
    field :slug, :id
    field :work_week_start, :integer
    field :work_week_end, :integer
  end

  @desc "time entries report"
  object :time_entries_report do
    field :row_count, :integer
    field :time_entry_report_items, list_of(:time_entry_report_item)
  end
end
