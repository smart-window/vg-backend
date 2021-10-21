defmodule Velocity.Schema.FormField do
  @moduledoc """
    Schema for form_fields.
    Represents a generic form field with configuration and source table mapping.
    This configuration and mapping can be overrideen on a per-country basis through form_fields_country.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "form_fields" do
    field :slug, :string
    field :type, FormFieldTypeEnum
    field :optional, :boolean
    field :source_table, :string
    field :source_table_field, :string
    field :config, :map

    # Computed in GQL queries, maps to source_table/source_table_field
    field :value, :string, virtual: true

    timestamps()
  end

  @doc false
  def changeset(changeset, attrs) do
    changeset
    |> cast(attrs, [
      :slug,
      :type,
      :optional,
      :source_table,
      :source_table_field,
      :config
    ])
    |> validate_required([
      :slug,
      :type,
      :source_table,
      :source_table_field
    ])
  end
end
