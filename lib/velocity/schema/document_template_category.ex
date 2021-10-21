defmodule Velocity.Schema.DocumentTemplateCategory do
  @moduledoc """
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "document_template_categories" do
    field :slug, :string
    field :entity_type, DocumentTemplateCategoryTypeEnum

    timestamps()
  end

  @doc false
  def changeset(document_template, attrs) do
    document_template
    |> cast(attrs, [])
    |> validate_required([])
  end
end
