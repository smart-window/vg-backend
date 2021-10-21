defmodule VelocityWeb.Resolvers.PartnerManagers do
  @moduledoc """
  GQL resolver for partner managers
  """

  alias Velocity.Contexts.PartnerManagers
  alias Velocity.Contexts.Users

  def get(args, _) do
    {:ok, PartnerManagers.get!(String.to_integer(args.id))}
  end

  def create(args, _) do
    # okta_user_uid is a random string until we have a clear workflow of how to create a new user login
    okta_user_uid = for _ <- 1..10, into: "", do: <<Enum.random('0123456789abcdef')>>

    {:ok, user} =
      Users.create(%{
        first_name: args.first_name,
        last_name: args[:last_name],
        email: args.email,
        okta_user_uid: okta_user_uid
      })

    PartnerManagers.create_partner_manager(%{
      user_id: user.id,
      partner_id: args.partner_id,
      job_title: args[:job_title]
    })
  end

  def delete(args, _) do
    PartnerManagers.delete_partner_manager(String.to_integer(args.id))
  end

  def paginated_partner_managers_report(args, _) do
    partner_manager_report_items =
      PartnerManagers.paginated_partner_managers_report(
        args.page_size,
        String.to_atom(Macro.underscore(args.sort_column)),
        String.to_atom(args.sort_direction),
        args.last_id,
        args.last_value,
        args.filter_by,
        args.search_by
      )

    row_count =
      if Enum.count(partner_manager_report_items) > 0 do
        Enum.at(partner_manager_report_items, 0)[:sql_row_count]
      else
        0
      end

    {:ok, %{row_count: row_count, partner_manager_report_items: partner_manager_report_items}}
  end

  def update_partner_manager(args, _) do
    PartnerManagers.update_partner_manager(args)
  end
end
