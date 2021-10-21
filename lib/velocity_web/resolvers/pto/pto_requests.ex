defmodule VelocityWeb.Resolvers.Pto.PtoRequests do
  @moduledoc """
  GQL resolver for pto types
  """

  alias Velocity.Contexts.Employments
  alias Velocity.Contexts.Pto.PtoRequests
  alias Velocity.Contexts.Pto.UserPolicies
  alias Velocity.Contexts.Users
  alias Velocity.Repo
  alias Velocity.Schema.Pto.PtoRequest
  alias Velocity.Schema.Pto.PtoRequestDay

  import Ecto.Query

  def get(args, _) do
    {:ok, PtoRequests.get!(String.to_integer(args.id))}
  end

  def create(args, _) do
    PtoRequests.create(args)
  end

  def update(args, _) do
    PtoRequests.update(args)
  end

  def delete(args, _) do
    PtoRequests.delete(String.to_integer(args.id))
  end

  def get_for_current_user(_args, %{context: %{current_user: current_user}}) do
    pto_requests =
      Repo.all(
        from pr in PtoRequest,
          join: e in assoc(pr, :employment),
          join: ee in assoc(e, :employee),
          where: ee.user_id == ^current_user.id
      )

    {:ok, pto_requests}
  end

  def create_with_days(args, %{context: %{current_user: current_user}}) do
    # ensure that there's a userPolicy for given accrual_policy_id and user_id
    UserPolicies.get_user_policy!(args.accrual_policy_id, args.user_id)

    if args.user_id != to_string(current_user.id) && !Users.is_user_internal(current_user) do
      {:error,
       "User #{current_user.id} is not authorized to add a pto request for user #{args.user_id}"}
    else
      current_employment = Employments.get_current_for_user(args.user_id)

      {:ok, pto_request} =
        PtoRequests.create(%{
          :user_id => args.user_id,
          :request_comment => args.request_comment,
          :employment_id => current_employment.id
        })

      inserted_and_updated_at = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

      pto_request_days_params =
        Enum.map(args.pto_request_days, fn input_pto_request_day ->
          %{
            pto_request_id: pto_request.id,
            accrual_policy_id: String.to_integer(args.accrual_policy_id),
            pto_type_id: String.to_integer(args.pto_type_id),
            day: input_pto_request_day.day,
            slot: input_pto_request_day.slot,
            inserted_at: inserted_and_updated_at,
            updated_at: inserted_and_updated_at
          }
        end)

      Repo.insert_all(PtoRequestDay, pto_request_days_params)

      {:ok, pto_request}
    end
  end
end
