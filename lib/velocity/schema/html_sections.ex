defmodule Velocity.Schema.HTMLSection do
  use Ecto.Schema
  import Ecto.Changeset

  alias Velocity.Schema.Country
  alias Velocity.Schema.EmailTemplate

  schema "html_sections" do
    field :html, :string
    field :order, :integer
    field :variables, {:array, :string}
    belongs_to :email_template, EmailTemplate
    belongs_to :country, Country

    timestamps()
  end

  @doc false
  def changeset(html_sections, attrs) do
    html_sections
    |> cast(attrs, [:html, :order, :variables])
    |> validate_required([:html])
  end
end
