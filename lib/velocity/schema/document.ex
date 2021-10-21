defmodule Velocity.Schema.Document do
  @moduledoc """
    Represents metadata for a document which may or may not have an upload.
    If there is no upload, this represents a placeholder to be filled out by the user or client.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Velocity.Schema.DocumentTemplate
  alias Velocity.Schema.DocumentTemplateCategory

  @fields [
    :name,
    :action,
    :file_type,
    :example_file_url,
    :example_filename,
    :document_template_id,
    :document_template_category_id,
    :status,
    :s3_key,
    :original_filename,
    :original_mime_type,
    :docusign_template_id,
    :docusign_envelope_id
  ]

  schema "documents" do
    field :name, :string
    field :action, :string
    field :file_type, :string
    field :example_file_url, :string
    field :example_filename, :string
    belongs_to :document_template, DocumentTemplate
    belongs_to :document_template_category, DocumentTemplateCategory
    field :status, :string
    field :s3_key, :string
    field :original_filename, :string
    field :original_mime_type, :string
    field :docusign_template_id, :string
    field :docusign_envelope_id, :string

    timestamps()
  end

  @doc false
  def changeset(document, attrs) do
    document
    |> cast(attrs, @fields)
    |> validate_required([])
  end
end
