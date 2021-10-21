defmodule Velocity.Contexts.EmailTemplates do
  alias Velocity.Repo
  alias Velocity.Schema.Client
  alias Velocity.Schema.ClientOnboarding
  alias Velocity.Schema.EmailTemplate
  alias Velocity.Schema.EmployeeOnboarding
  alias Velocity.Schema.Employment
  alias Velocity.Schema.HTMLSection
  alias Velocity.Schema.Process
  alias Velocity.Schema.Task
  alias Velocity.Schema.User

  import Ecto.Query

  require Logger

  def list_templates do
    Repo.all(EmailTemplate)
  end

  def get_template(id, country_id \\ nil, vars \\ %{}) do
    get_and_resolve_template(id, country_id, vars)
  end

  # credo:disable-for-this-file Credo.Check.Refactor.Nesting

  @doc """
    email_templates is assumed to be a list of maps with each map representing
    an email template to import. This supports updating existing notification
    templates as well.
    The following input format is supported for each email template map:
      %{
        name: <name of email template>
        subject: <email subject> (optional)
        html_sections: [
          {
            html: <html for section> (required)
          }
        ]
      }
    Note that order for html_sections is inferred from html_sections list
    order.
  """
  def import(email_templates) do
    Repo.transaction(fn ->
      Enum.reduce(email_templates, [], fn email_template_config, acc ->
        inserted_and_updated_at =
          NaiveDateTime.utc_now()
          |> NaiveDateTime.truncate(:second)

        email_template_name = Map.fetch!(email_template_config, :name)

        Repo.insert(
          %EmailTemplate{
            name: email_template_name,
            subject: Map.get(email_template_config, :subject),
            inserted_at: inserted_and_updated_at,
            updated_at: inserted_and_updated_at
          },
          conflict_target: [:name],
          on_conflict: {:replace, [:subject, :updated_at]}
        )

        email_template = Repo.get_by!(EmailTemplate, name: email_template_name)

        # delete any html_sections currently defined
        from(hs in HTMLSection, where: hs.email_template_id == ^email_template.id)
        |> Repo.delete_all()

        # insert new html_sections
        Map.get(email_template_config, :html_sections, [])
        |> Enum.with_index()
        |> Enum.each(fn {html_section_config, section_index} ->
          Repo.insert(%HTMLSection{
            email_template_id: email_template.id,
            order: section_index + 1,
            html: Map.fetch!(html_section_config, :html),
            inserted_at: inserted_and_updated_at,
            updated_at: inserted_and_updated_at
          })
        end)

        acc ++ [email_template]
      end)
    end)
  end

  def get_template_by_name(name, country_id \\ nil, contexts \\ []) do
    vars = resolve_contexts(contexts)
    email_template = Repo.get_by!(EmailTemplate, name: name)
    get_and_resolve_template(email_template.id, country_id, vars)
  end

  defp get_and_resolve_template(id, country_id, vars) do
    preload_query =
      if country_id do
        from(hs in HTMLSection, where: hs.country_id == ^country_id or is_nil(hs.country_id))
      else
        from(hs in HTMLSection, where: is_nil(hs.country_id))
      end

    query =
      from(et in EmailTemplate,
        where: et.id == ^id,
        preload: [
          html_sections: ^preload_query
        ]
      )

    query
    |> Repo.one()
    |> (fn
          nil ->
            nil

          email_template ->
            hydrated_sections =
              Enum.map(email_template.html_sections, fn section ->
                hydrate_section(section, vars)
              end)

            hydrated_subject = do_substitution(email_template.subject, vars)

            email_template
            |> Map.put(:html_sections, hydrated_sections)
            |> Map.put(:subject, hydrated_subject)
        end).()
  end

  def hydrate_section(section, metadata) do
    html = do_substitution(section.html, metadata)
    Map.put(section, :html, html)
  end

  defp resolve_contexts(nil) do
    %{}
  end

  defp resolve_contexts(contexts) do
    contexts
    |> Enum.reduce(%{}, fn context, acc ->
      Map.put(acc, String.to_atom(context.name), resolve_context(context))
    end)
  end

  defp resolve_context(context) when is_map_key(context, :value) do
    context[:value]
  end

  defp resolve_context(context = %{type: "User"}) do
    Repo.get(User, context.id)
  end

  defp resolve_context(context = %{type: "Client"}) do
    Repo.get(Client, context.id)
  end

  defp resolve_context(context = %{type: "Employment"}) do
    Repo.get(Employment, context.id)
  end

  defp resolve_context(context = %{type: "Task"}) do
    Repo.get(Task, context.id)
  end

  defp resolve_context(context = %{type: "ClientOnboarding"}) do
    Repo.get(ClientOnboarding, context.id)
  end

  defp resolve_context(context = %{type: "EmployeeOnboarding"}) do
    Repo.get(EmployeeOnboarding, context.id)
  end

  defp resolve_context(context = %{type: "Process"}) do
    Repo.get(Process, context.id)
  end

  def do_substitution(nil, _metadata) do
    ""
  end

  @doc """
    Any instance of {{key}} found in the value is replaced with
    the value of key from the provided metadata. For example, if
    metadata looks like this:
    %{
      first_name: "John"
      last_name: "Jones"
      ...
    }
    and the value provided is:

     "Hello {{first_name}} {{last_name}}, How are you?"

    then the text returned will be:

     "Hello John Jone, How are you?"

    A nested traversal of metadata values is supported. Any '.' 
    character encountered in the key will assume the value represents
    either a map or a struct and will attempted to be traversed. This
    traversal also supports schema belongs to or has one relationships
    if the key value in question represents a schema object instance. 

    For example with the metadata object of:

    %{
      employment: <employment schema object>
      ...
    }

    and a value of:

    "Your current country of employment is {{employment.country.name}}"

    will result in the text:

    "Your current country of employment is Germany"

    even if the country association for the employment object has not
    been loaded.

    TODO: maybe move the following methods to a helper file so that
    more than email templates might be able to leverage the variable
    substitution
  """
  def do_substitution(value, metadata) do
    Regex.replace(~r/{{(.*)}}/U, value, fn _whole, key ->
      String.split(key, ".")
      |> Enum.reduce(metadata, fn part, acc -> get_substitution_value(acc, part) end)
      |> to_string
    end)
  end

  defp get_substitution_value("", _part) do
    ""
  end

  defp get_substitution_value(acc, part) do
    get_next_substitution_value(acc, part, Map.fetch(acc, String.to_atom(part)))
  end

  defp get_next_substitution_value(acc, part, {:ok, %Ecto.Association.NotLoaded{}}) do
    Ecto.assoc(acc, String.to_atom(part)) |> Repo.one()
  end

  defp get_next_substitution_value(_acc, _part, {:ok, next}) do
    next || ""
  end

  defp get_next_substitution_value(acc, part, :error) do
    Logger.warn("part #{part} not found for context #{inspect(acc)}")
    ""
  end
end
