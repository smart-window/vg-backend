defmodule VelocityWeb.Controllers.CsvController do
  use VelocityWeb, :controller

  alias Ecto.Query
  # alias Velocity.Contexts.RoleAssignments
  alias Velocity.Contexts.Forms
  alias Velocity.Contexts.TimeTracking
  alias Velocity.Contexts.Training.EmployeeTrainings
  alias Velocity.Repo
  alias Velocity.Schema.User
  import Ecto.Query

  # TODO: i18n consideration for headers
  # TODO: use proper employee id (instead of time entry id)
  # TODO: update region when available
  @time_entry_columns ~w(
    id
    user_full_name
    user_client_name
    user_work_address_country_name
    user_work_address_country_name
    event_date
    total_hours
    time_type_slug
    description
  )a
  @time_entry_column_headers [
    "Time Entry ID",
    "Employee Name",
    "Client",
    "Region",
    "Country",
    "Time Entry Date",
    "Hours",
    "Time Category",
    "Description"
  ]

  @training_columns ~w(
    id
    user_full_name
    user_client_name
    user_client_name
    user_work_address_country_name
    user_work_address_country_name
    training_name
    status
    due_date
    completed_date
  )a
  @training_column_headers [
    "Employee ID",
    "Employee Name",
    "Partner",
    "Client",
    "Region",
    "Country",
    "Module Name",
    "Status",
    "Due Date",
    "Completion Date"
  ]

  @form_labels %{
    "eeww-basic-info": "Basic Information",
    "eeww-personal-info": "Personal Information",
    "eeww-contact-info": "Contact Information",
    "eeww-bank-info": "Bank Information",
    "eeww-work-info": "Work Information",
    "eeww-identification-info": "Identification Information",
    "eeww-other-info": "Other Information",
    "eeprofile-personal-info": "Personal Information",
    "eeprofile-contact-info": "Contact Information"
  }
  @form_field_headers [
    "Category",
    "Name",
    "Field Label",
    "Contents"
  ]

  def time_entries(conn, params) do
    _current_user = conn.assigns.context.current_user

    filename = set_filename(params, "time_tracking.csv")
    csv_delimiter = get_csv_delimiter(params) |> String.to_charlist() |> hd()
    conn = initialize_response(conn, filename)
    send_headers(conn, @time_entry_column_headers, csv_delimiter)

    # role_assignment_type = RoleAssignments.get_assignment_type(current_user, "employee-reporting")

    # credo:disable-for-lines:35 Credo.Check.Refactor.Nesting
    # if not is_nil(role_assignment_type) do
    filter_by = get_filter_by(params)
    search_by = get_search_by(params)
    # current possiblilities are "global", "external", or nil
    # only_ee_entries = role_assignment_type == "external"
    only_ee_entries = false

    query =
      TimeTracking.time_entry_report_query(
        String.to_atom(Macro.underscore(params[:sort_column])),
        String.to_atom(params[:sort_direction]),
        0,
        "",
        filter_by,
        search_by,
        only_ee_entries
      )

    query =
      if Map.has_key?(params, :ids) do
        ids = String.split(params[:ids], ",")
        ids_where = dynamic([te], te.id in ^ids)
        Query.where(query, ^ids_where)
      else
        query
      end

    Repo.transaction(fn ->
      query
      |> Repo.stream()
      |> Stream.map(&parse_time_entries/1)
      |> CSV.encode(separator: csv_delimiter)
      |> Enum.map(fn item -> conn |> chunk(item) end)
    end)

    # end

    conn
  end

  def training(conn, params) do
    filename = set_filename(params, "training.csv")
    conn = initialize_response(conn, filename)
    csv_delimiter = get_csv_delimiter(params) |> String.to_charlist() |> hd()
    send_headers(conn, @training_column_headers, csv_delimiter)
    filter_by = get_filter_by(params)
    search_by = get_search_by(params)

    query =
      EmployeeTrainings.employee_trainings_report_query(
        String.to_atom(Macro.underscore(params[:sort_column])),
        String.to_atom(params[:sort_direction]),
        0,
        "",
        filter_by,
        search_by
      )

    query =
      if Map.has_key?(params, :ids) do
        ids = String.split(params[:ids], ",")
        ids_where = dynamic([te], te.id in ^ids)
        Query.where(query, ^ids_where)
      else
        query
      end

    Repo.transaction(fn ->
      query
      |> Repo.stream()
      |> Stream.map(&parse_trainings/1)
      |> CSV.encode(separator: csv_delimiter)
      |> Enum.map(fn item -> conn |> chunk(item) end)
    end)

    conn
  end

  def form_field_values(conn, params) do
    filename = set_filename(params, "form_field_values.csv")
    conn = initialize_response(conn, filename)
    csv_delimiter = get_csv_delimiter(params) |> String.to_charlist() |> hd()
    send_headers(conn, @form_field_headers, csv_delimiter)

    if Map.has_key?(params, :form_slugs) && Map.has_key?(params, :user_id) do
      {user_id, _} = Integer.parse(params[:user_id])
      user = Repo.get(User, user_id)
      form_slugs = String.split(params[:form_slugs], ",")
      {:ok, forms} = Forms.get_forms_fields_and_values(form_slugs, user)

      forms
      |> Enum.each(fn form ->
        chunk_form_fields(conn, form, user, csv_delimiter)
      end)
    end

    conn
  end

  defp parse_time_entries(time_entry) do
    Enum.map(@time_entry_columns, &Map.get(time_entry, &1))
  end

  defp parse_trainings(training) do
    Enum.map(@training_columns, &Map.get(training, &1))
  end

  defp chunk_form_fields(conn, form, user, csv_delimiter) do
    form.form_fields
    |> Enum.map(fn field ->
      form_slug = String.to_atom(form.slug)

      form_label =
        if Map.has_key?(@form_labels, form_slug) do
          @form_labels[form_slug]
        else
          form.slug
        end

      field_label =
        String.replace(field.slug, "-", " ")
        |> String.split()
        |> Enum.map(&String.capitalize/1)
        |> Enum.join(" ")

      field_chunk =
        [[form_label, user.full_name, field_label, field.value]]
        |> CSV.encode(separator: csv_delimiter)
        |> Enum.to_list()
        |> to_string

      conn |> chunk(field_chunk)
    end)
  end

  defp set_filename(params, default_filename) do
    if Map.has_key?(params, :filename) do
      params[:filename]
    else
      default_filename
    end
  end

  defp initialize_response(conn, filename) do
    conn
    |> put_resp_content_type("text/csv")
    |> put_resp_header("content-disposition", "attachment; filename=\"#{filename}\"")
    |> send_chunked(:ok)
  end

  defp send_headers(conn, headers, csv_delimiter) do
    header_chunk =
      [headers]
      |> CSV.encode(separator: csv_delimiter)
      |> Enum.to_list()
      |> to_string

    conn |> chunk(header_chunk)
  end

  defp get_filter_by(params) do
    if Map.has_key?(params, :filter_by) do
      Enum.reduce(String.split(params[:filter_by], ";"), [], fn filter, filter_by ->
        [name, value] = String.split(filter, "|")
        filter_by ++ [%{name: name, value: value}]
      end)
    else
      []
    end
  end

  defp get_search_by(params) do
    if Map.has_key?(params, :search_by) do
      params[:search_by]
    else
      nil
    end
  end

  defp get_csv_delimiter(params) do
    if Map.has_key?(params, :csv_delimiter) do
      params[:csv_delimiter]
    else
      # default to comma delimiters
      ","
    end
  end
end
