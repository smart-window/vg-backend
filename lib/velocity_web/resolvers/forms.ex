defmodule VelocityWeb.Resolvers.Forms do
  @moduledoc """
    resolver for forms (including form fields)
  """

  import Ecto.Query

  alias Velocity.Contexts.Employments
  alias Velocity.Contexts.Forms
  alias Velocity.Contexts.Users
  alias Velocity.Repo

  @table_schema_map %{
    "addresses" => Velocity.Schema.Address
  }

  @doc """
    Return a list of VelocityWeb.Schema.FormTypes.form_field,
    which is a form_field merged with form_form_field overrides and a source_table value
    for current user.
  """
  def get_fields_with_values_for_current_user(_args = %{form_slug: form_slug}, %{
        context: %{current_user: current_user}
      }) do
    Forms.get_fields_with_values(form_slug, current_user)
  end

  @doc """
    Return a list of VelocityWeb.Schema.FormTypes.form_field,
    which is a form_field merged with form_form_field overrides and a source_table value
    for a user.
  """
  def get_fields_with_values_for_user(_args = %{form_slug: form_slug, user_id: user_id}, %{
        context: %{current_user: current_user}
      }) do
    # TODO: add permissions/asignments check to make sure the user asking can get this info
    if Users.is_user_internal(current_user) do
      user = Users.get_by(id: user_id)
      Forms.get_fields_with_values(form_slug, user)
    else
      {:error, "User #{current_user.id} is not authorized"}
    end
  end

  @doc """
    Return a map of slug -> VelocityWeb.Schema.FormTypes.form, with form field values embedded for current user.
  """
  def get_forms_fields_and_values_for_current_user(_args = %{form_slugs: form_slugs}, %{
        context: %{current_user: current_user}
      }) do
    Forms.get_forms_fields_and_values(form_slugs, current_user)
  end

  @doc """
    Return a map of slug -> VelocityWeb.Schema.FormTypes.form, with form field values embedded for a passed in user.
  """
  def get_forms_fields_and_values_for_user(_args = %{form_slugs: form_slugs, user_id: user_id}, %{
        context: %{current_user: current_user}
      }) do
    # TODO: add permissions/asignments check to make sure the user asking can get this info
    if Users.is_user_internal(current_user) do
      user = Users.get_by(id: user_id)
      Forms.get_forms_fields_and_values(form_slugs, user)
    else
      {:error, "User #{current_user.id} is not authorized"}
    end
  end

  def can_current_user_access_user(current_user) do
    current_user_with_groups = Repo.preload(current_user, :groups)

    is_admin =
      Enum.find(current_user_with_groups.groups, fn group ->
        group.slug == "admin" || group.slug == "csr"
      end)

    if is_admin != nil do
      true
    else
      false
    end
  end

  @doc """
    Update source table field values for the given form_form_field ids and current user.
    form_field_values is a list of {id: _ , value: _ }
  """
  def save_field_values_for_current_user(_args = %{field_values: form_field_values}, %{
        context: %{current_user: current_user}
      }) do
    save_field_values(%{field_values: form_field_values, user: current_user})
  end

  @doc """
    Update source table field values for the given form_form_field ids and current user.
    form_field_values is a list of {id: _ , value: _ }
  """
  def save_field_values_for_user(_args = %{field_values: form_field_values, user_id: user_id}, %{
        context: %{current_user: current_user}
      }) do
    # TODO: add permissions/asignments check to make sure the user can take this action
    if Users.is_user_internal(current_user) do
      user = Users.get_by(id: user_id)
      save_field_values(%{field_values: form_field_values, user: user})
    else
      {:error, "User #{current_user.id} is not authorized"}
    end
  end

  defp save_field_values(_args = %{field_values: form_field_values, user: user}) do
    employment = Employments.get_for_user(user.id)
    form_form_field_ids = Enum.map(form_field_values, fn field -> field.id end)

    fields_to_save =
      Forms.get_fields_for_country_by_ids(
        form_form_field_ids,
        employment.country_id
      )

    form_field_values_map = build_form_fields_value_map(form_field_values)

    # use above data structures to generate a map from tables to fields to be updated and their values
    source_tables_to_update =
      Enum.reduce(fields_to_save, %{}, fn field, acc ->
        value_for_field = Map.get(form_field_values_map, Integer.to_string(field.id))
        key = "#{field.source_table}.#{field.config["foreign_key_path"]}"

        set_of_fields =
          if Map.has_key?(acc, key) do
            #  Add %{source_field: value} to Map for source_table
            Map.put(
              acc[key],
              field.source_table_field,
              value_for_field
            )
          else
            # Initialize new Map containing %{source_field: value} under source_table
            Map.put(%{}, field.source_table_field, value_for_field)
          end

        Map.put(acc, key, set_of_fields)
      end)

    # save relevant values to each source table fields
    updates_successful =
      Enum.reduce(source_tables_to_update, true, fn {key, fields_to_save}, acc ->
        [source_table | foreign_key_path] = String.split(key, ".")
        foreign_key_table = Enum.at(foreign_key_path, 0)
        foreign_key_table_field = Enum.drop(foreign_key_path, 1)

        # For jsonb fields, generate dynamic fragment leveraging jsonb_set
        set_statements = build_jsonb_set_statements(source_table, user.id, fields_to_save)

        reference_id =
          if foreign_key_table_field != [] do
            # if field has a foreign_key_path, finds the referenced foreign key on the user
            [foreign_key_path_column | rest] = foreign_key_table_field
            reference_id_path = [String.to_atom(foreign_key_path_column) | rest]

            get_in(
              Map.from_struct(user),
              reference_id_path
            )
          else
            # otherwise use user.id
            user.id
          end

        update_query =
          if reference_id do
            # if the foreign_key_path references a non-nil id, perform an update
            from(x in source_table,
              update: [set: ^set_statements],
              where: x.id == ^reference_id
            )
          else
            # if the foreign_key_path references a nil id, a create new source table row
            # and update on foreign_key_path reference
            inserted_and_updated_at = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

            insert =
              set_statements
              |> Enum.reduce(%{}, fn {key, value}, acc ->
                Map.put(acc, key, value)
              end)
              |> Map.put(:inserted_at, inserted_and_updated_at)
              |> Map.put(:updated_at, inserted_and_updated_at)

            # create a new entry in source table
            {1, [row | _]} =
              Repo.insert_all(
                Map.get(@table_schema_map, source_table),
                [insert],
                returning: true
              )

            foreign_key_update_statements =
              if length(foreign_key_table_field) == 1 do
                Enum.map(foreign_key_table_field, fn key -> {String.to_atom(key), row.id} end)
              else
                # only runs if foreign key path is referencing a jsonb column
                build_jsonb_set_statements(foreign_key_table, user.id, %{
                  Enum.join(foreign_key_table_field, ".") => row.id
                })
              end

            # update the column the foreign_key_path references for user with the newly inserted row
            from(x in foreign_key_table,
              update: [set: ^foreign_key_update_statements],
              where: x.id == ^user.id
            )
          end

        # if update count ever less than or more than 1 row, the update will not be successful
        case Repo.update_all(update_query, []) do
          {1, _} ->
            acc

          {_0, _} ->
            false
        end
      end)

    if updates_successful do
      # return fields with newly saved value
      fields_to_return =
        Enum.map(fields_to_save, fn field ->
          saved_value = Map.get(form_field_values_map, Integer.to_string(field.id))
          Map.merge(field, %{value: saved_value})
        end)

      {:ok, fields_to_return}
    else
      {:error, "Error updating source values for given fields"}
    end
  end

  defp build_jsonb_set_statements(source_table, source_table_pkey, fields_to_save) do
    # Find all unique jsonb columns we need from source_table
    json_columns_set =
      Enum.reduce(fields_to_save, MapSet.new(), fn {field, _val}, acc ->
        if String.contains?(field, ".") do
          json_column = hd(String.split(field, "."))
          acc |> MapSet.put(json_column)
        else
          acc
        end
      end)

    json_columns_list =
      json_columns_set |> MapSet.to_list() |> Enum.map(&String.to_existing_atom/1)

    # Query current values of json columns if we have any
    # We could avoid this query with Postgres' jsonb_set, but we'd have to use raw sql and sanitize input ourselves
    current_json_values =
      if Enum.empty?(json_columns_list) do
        %{}
      else
        Repo.one(
          from(x in source_table,
            where: x.id == ^source_table_pkey,
            select: ^json_columns_list
          )
        )
      end

    # Reduce fields_to_save with mapped values
    Enum.reduce(fields_to_save, %{}, fn {field, val}, acc ->
      split_json_keys = String.split(field, ".")
      json_column = hd(split_json_keys)

      if MapSet.member?(json_columns_set, json_column) do
        # jsonb field, merge with current value
        existing_json = current_json_values[String.to_existing_atom(json_column)]

        # Drop first key (column) and use Access.key/2 to handle keys that don't exist yet
        path_to_key = split_json_keys |> Enum.drop(1) |> Enum.map(&Access.key(&1, %{}))

        updated_json = put_in(existing_json || %{}, path_to_key, val)
        Map.put(acc, json_column, updated_json)
      else
        # non-jsonb field
        Map.put(acc, field, val)
      end
    end)
    # convert from map to keyword list
    # TODO: Need some sort of way to calculate WHAT data type it is (all values are string, could be int, date, etc.)
    |> Enum.map(fn {column, val} -> {String.to_existing_atom(column), val} end)
  end

  defp build_form_fields_value_map(form_field_values) do
    # Convert input array to map of id => value for easy lookup
    Map.new(form_field_values, fn
      %{data_type: "date", id: id, value: value} ->
        value = if value, do: Date.from_iso8601!(value), else: value
        {id, value}

      %{data_type: data_type, id: id, value: value}
      when data_type in ["id", "integer", "number"] ->
        value =
          if is_nil(value) || String.trim(value) == "", do: nil, else: String.to_integer(value)

        {id, value}

      %{id: id, value: value} ->
        trimmed_value = String.trim(value)
        sanitized_value = if trimmed_value == "", do: nil, else: trimmed_value
        {id, sanitized_value}
    end)
  end
end
