defmodule Velocity.Schema.DocumentTemplate do
  @moduledoc """
    Templates used by admins to create document records for end users to fill out.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Velocity.Schema.Client
  alias Velocity.Schema.Country
  alias Velocity.Schema.DocumentTemplateCategory
  alias Velocity.Schema.Partner

  @fields [
    :id,
    :name,
    :file_type,
    :action,
    :instructions,
    :required,
    :example_file_url,
    :example_filename,
    :example_file_mime_type,
    :client_id,
    :country_id,
    :partner_id,
    :document_template_category_id
  ]

  schema "document_templates" do
    field :name, :string
    field :file_type, :string
    field :action, :string
    field :instructions, :string
    field :required, :boolean
    field :example_file_mime_type, :string
    field :example_file_url, :string
    field :example_filename, :string

    belongs_to :document_template_category, DocumentTemplateCategory
    belongs_to :client, Client
    belongs_to :country, Country
    belongs_to :partner, Partner

    timestamps()
  end

  @doc false
  def changeset(document_template, attrs) do
    document_template
    |> cast(attrs, @fields)
    |> validate_required([])
  end
end
