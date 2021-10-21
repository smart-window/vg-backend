defmodule VelocityWeb.Schema.FormTypes do
  @moduledoc """
  GQL types for all entities used in form operations
  """
  use Absinthe.Schema.Notation

  @desc "form"
  object :form do
    field :id, :id
    field :slug, :id
    field :task_id, :id
    field :form_fields, list_of(:form_field)
  end

  @desc "form field"
  object :form_field do
    field :id, :id
    field :slug, :id
    field :country_id, :id
    field :optional, :boolean
    field :config, :json
    field :type, :string
    field :value, :string
    field :source_table_field, :string
  end

  input_object :form_values do
    field :form_slug, :id
    field :form_field_values, list_of(:form_field_value)
  end

  # This shouldn't matter to the client, but it's important to note that :id
  # is a form_form_field id (also sent back as :id in the form_fields query)
  # and :data_type is the data type the value should be converted to
  input_object :form_field_value do
    field :id, :id
    field :slug, :string
    field :value, :string
    field :data_type, :string
  end
end
