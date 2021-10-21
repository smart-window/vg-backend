defmodule Velocity.Schema.PartnerManager do
  use Ecto.Schema
  import Ecto.Changeset

  alias Velocity.Schema.Partner
  alias Velocity.Schema.User
  alias Velocity.Utils.Changesets, as: Utils

  schema "partner_managers" do
    field :job_title, :string
    belongs_to :partner, Partner
    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(partner_manager, attrs) do
    partner_manager
    |> cast(attrs, [:job_title, :partner_id, :user_id])
    |> validate_required([:job_title, :partner_id, :user_id])
    |> Utils.maybe_put_assoc(:partner, attrs)
    |> Utils.maybe_put_assoc(:user, attrs)
  end
end
