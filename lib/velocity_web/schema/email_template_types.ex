defmodule VelocityWeb.Schema.EmailTemplateTypes do
  @moduledoc false
  use Absinthe.Schema.Notation

  @desc "email_template"
  object :email_template do
    field(:id, :id)
    field(:name, :string)
    field(:subject, :string)
    field(:from_role, :string)
    field(:to_role, :string)
    field(:html_sections, list_of(:html_section))
  end

  object :html_section do
    field :html, :string
    field :order, :integer
  end

  input_object :email_attachment_input do
    field :url, :string
    field :filename, :string
    field :content_type, :string
    field :document_id, :id
  end

  # email_address required but user_id is optional (these will be stored
  # into email_sent_users)
  input_object :email_recipient do
    field :email_address, :string
    field :user_id, :id
  end

  @doc """
    name is required. Then the value to use for name can either be an actual
    value (value field) or reference a database entity (id and type field
    pair). The field value takes precedence in processing.
    For example, an email_variable that looks like:
      %{
        name: "email_address",
        value: "fubar@fubar.com"
      }
    will result in a key of "email_address" and a value of "fubar@fubar.com"
    being added to the variables provided to an email template.
    An email_variable that looks like:
      %{
        name: "user",
        type: "User",
        id: 23
      }
    will result in a key of "user" and a value of Repo.get!(User, id) being
    added to the variables provided to an email template.
  """
  input_object :email_variable do
    field :name, :string
    field :id, :id
    field :type, :string
    field :value, :string
  end
end
