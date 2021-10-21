defmodule VelocityWeb.Resolvers.Partners do
  @moduledoc """
  GQL resolver for partners
  """

  alias Velocity.Contexts.Partners

  def get(args, _) do
    {:ok, Partners.get!(String.to_integer(args.id))}
  end

  def create(args, _) do
    Partners.create(args)
  end

  def update(args, _) do
    Partners.update(args)
  end

  def delete(args, _) do
    Partners.delete(String.to_integer(args.id))
  end

  def all(_args, _) do
    {:ok, Partners.all()}
  end

  def paginated_partners_report(args, _) do
    partner_report_items =
      Partners.paginated_partners_report(
        args.page_size,
        String.to_atom(Macro.underscore(args.sort_column)),
        String.to_atom(args.sort_direction),
        args.last_id,
        args.last_value,
        args.filter_by,
        args.search_by
      )

    row_count =
      if Enum.count(partner_report_items) > 0 do
        Enum.at(partner_report_items, 0)[:sql_row_count]
      else
        0
      end

    {:ok, %{row_count: row_count, partner_report_items: partner_report_items}}
  end
end
