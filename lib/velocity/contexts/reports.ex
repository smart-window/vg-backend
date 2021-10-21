defmodule Velocity.Contexts.Reports do
  @moduledoc "helper methods for virtually paged report queries"

  import Ecto.Query

  def last_record_clause(sort_direction, primary, _table, _sort_column, last_id, nil) do
    if sort_direction == :asc do
      dynamic(
        [{^primary, p}],
        p.id > ^last_id
      )
    else
      dynamic(
        [{^primary, p}],
        p.id > ^last_id
      )
    end
  end

  def last_record_clause(sort_direction, primary, table, sort_column, last_id, last_value) do
    if sort_direction == :asc do
      dynamic(
        [{^primary, p}, {^table, x}],
        field(x, ^sort_column) > ^last_value or
          (field(x, ^sort_column) == ^last_value and p.id > ^last_id)
      )
    else
      dynamic(
        [{^primary, p}, {^table, x}],
        field(x, ^sort_column) < ^last_value or
          (field(x, ^sort_column) == ^last_value and p.id > ^last_id)
      )
    end
  end
end
