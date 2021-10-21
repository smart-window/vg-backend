defmodule Velocity.Contexts.Forms do
  @moduledoc """
  context for forms and form_fields
  """
  import Ecto.Query

  alias Ecto.Adapters.SQL
  alias Velocity.Contexts.Employments
  alias Velocity.Repo
  alias Velocity.Schema.Form
  alias Velocity.Schema.FormField
  alias Velocity.Schema.FormFormField

  def get_by(keyword) do
    Repo.get_by(Form, keyword)
  end

  def get_fields_for_country_by_form(form_slug, country_id) do
    fields_query =
      from(ff in FormField,
        join: fff in FormFormField,
        on: fff.form_field_id == ff.id,
        join: f in Form,
        on: f.slug == ^form_slug and f.id == fff.form_id,
        where: is_nil(fff.country_id) or fff.country_id == ^country_id,
        select: %{
          id: fff.id,
          slug: ff.slug,
          country_id: fff.country_id,
          type: fff.type_override |> coalesce(ff.type),
          optional: fff.optional_override |> coalesce(ff.optional),
          source_table: fff.source_table_override |> coalesce(ff.source_table),
          source_table_field: fff.source_table_field_override |> coalesce(ff.source_table_field),
          config: fragment("coalesce(? || ?, ?)", ff.config, fff.config_override, ff.config)
        },
        distinct: true
      )

    Repo.all(fields_query)
  end

  def get_fields_for_country_by_ids(form_form_field_ids, country_id) do
    in_field_ids_clause = dynamic([ff, fff], fff.id in ^form_form_field_ids)

    fields_query =
      from(ff in FormField,
        left_join: fff in FormFormField,
        on: fff.form_field_id == ff.id,
        where: fff.country_id == ^country_id or is_nil(fff.country_id),
        where: ^in_field_ids_clause,
        select: %{
          id: fff.id,
          slug: ff.slug,
          country_id: fff.country_id,
          type: fff.type_override |> coalesce(ff.type),
          optional: fff.optional_override |> coalesce(ff.optional),
          source_table: fff.source_table_override |> coalesce(ff.source_table),
          source_table_field: fff.source_table_field_override |> coalesce(ff.source_table_field),
          config: fragment("coalesce(? || ?, ?)", ff.config, fff.config_override, ff.config)
        },
        distinct: true
      )

    Repo.all(fields_query)
  end

  def get_forms_fields_and_values(form_slugs, user) do
    forms = Enum.map(form_slugs, fn form_slug -> get_by(slug: form_slug) end)

    forms_with_fields_and_values =
      Enum.map(forms, fn form ->
        {_, fields_with_values} = get_fields_with_values(form.slug, user)
        Map.put(form, :form_fields, fields_with_values)
      end)

    {:ok, forms_with_fields_and_values}
  end

  def get_fields_with_values(form_slug, user) do
    # Get relevant form_fields
    employment = Employments.get_for_user(user.id)

    form_fields =
      get_fields_for_country_by_form(
        form_slug,
        employment.country_id
      )

    # Builds a list of fields we need for each table for each foreign key path
    source_tables_and_fields =
      form_fields
      |> Enum.reduce([], fn field, acc ->
        [{field.source_table, field.config["foreign_key_path"]} | acc]
      end)
      |> Enum.uniq_by(fn elem ->
        elem
      end)

    # Populate values for each table / set of fields
    source_tables_with_values =
      Enum.reduce(source_tables_and_fields, %{}, fn
        # Runs if form field values can be derived from data within source table
        {source_table, nil}, acc ->
          query_string = "SELECT * FROM #{source_table} WHERE #{source_table}.id = #{user.id}"

          formatted_result = format_result(SQL.query!(Repo, query_string))

          Map.put(acc, source_table, formatted_result)

        # Runs if form field values must be derived via a reference (foreign_key_path)
        # in a table other than the source table
        {source_table, foreign_key_path}, acc ->
          split_foreign_key_path = String.split(foreign_key_path, ".")
          [root_table | foreign_key_path_without_table] = split_foreign_key_path

          if length(split_foreign_key_path) == 2 do
            # Selects the correct values if the foreign_key_path directly references a field on another table
            query_string =
              "SELECT * FROM #{source_table} INNER JOIN #{root_table} on #{foreign_key_path} = #{
                source_table
              }.id
                    where #{root_table}.id = #{user.id}"

            formatted_result = format_result(SQL.query!(Repo, query_string))

            Map.put(acc, "#{source_table}#{foreign_key_path}", formatted_result)
          else
            # Selects the correct values if the foreign_key_path references a key within jsonb
            {root_table_field, list_without_field} =
              List.pop_at(foreign_key_path_without_table, 0)

            joined_list_without_field = Enum.join(list_without_field, "->")

            query_string =
              "select * from #{source_table}
              inner join #{root_table} on (#{root_table}.#{root_table_field}->'#{
                joined_list_without_field
              }')::bigint = #{source_table}.id
              where #{root_table}.id = #{user.id};"

            formatted_result = format_result(SQL.query!(Repo, query_string))

            Map.put(acc, "#{source_table}#{foreign_key_path}", formatted_result)
          end
      end)

    # Finally, populate values to form_fields
    fields_with_values =
      Enum.map(form_fields, fn field ->
        key =
          field
          |> Map.get(:config)
          |> (fn
                nil ->
                  ""

                map ->
                  Map.get(map, "foreign_key_path", "")
              end).()

        [first | rest] = String.split(field.source_table_field, ".")
        get = [String.to_atom(first) | rest]

        value =
          get_in(
            source_tables_with_values["#{field.source_table}#{key}"],
            get
          )

        Map.put(field, :value, value)
      end)

    {:ok, fields_with_values}
  end

  defp format_result(results) do
    case results do
      %{num_rows: num_rows} when num_rows > 0 ->
        result_cols = Enum.map(results.columns, &String.to_atom/1)
        result_map = Enum.zip(result_cols, hd(results.rows))
        result_map

      _ ->
        []
    end
  end
end
