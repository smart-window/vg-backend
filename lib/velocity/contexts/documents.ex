defmodule Velocity.Contexts.Documents do
  alias Ecto.Multi
  alias Ecto.Query
  alias Velocity.Repo
  alias Velocity.Schema.Client
  alias Velocity.Schema.ClientDocument
  alias Velocity.Schema.Country
  alias Velocity.Schema.Document
  alias Velocity.Schema.DocumentTemplate
  alias Velocity.Schema.DocumentTemplateCategory
  alias Velocity.Schema.Partner
  alias Velocity.Schema.User
  alias Velocity.Schema.UserDocument

  import Ecto.Query

  @document_template_preloads [:document_template_category, :country, :client, :partner]
  @document_preloads [:document_template]
  def upsert_document_template(args) do
    if id = Map.get(args, :id) do
      document_template = Repo.get!(DocumentTemplate, id)
      changeset = DocumentTemplate.changeset(document_template, args)

      {:ok, Repo.update!(changeset) |> Repo.preload(@document_template_preloads)}
    else
      changeset = DocumentTemplate.changeset(%DocumentTemplate{}, args)

      {:ok, Repo.insert!(changeset) |> Repo.preload(@document_template_preloads)}
    end
  end

  def create_user_document(input_document, user) do
    if id = Map.get(input_document, :id) do
      document = Repo.get!(Document, id)
      changeset = Document.changeset(document, input_document)

      {:ok, Repo.update!(changeset) |> Repo.preload(@document_preloads)}
    else
      changeset = Document.changeset(%Document{}, input_document)
      created_document = Repo.insert!(changeset) |> Repo.preload(@document_preloads)

      user_document_changeset =
        UserDocument.changeset(%UserDocument{}, %{
          user: user,
          document: created_document
        })

      _user_document_records = Repo.insert!(user_document_changeset)

      {:ok, created_document}
    end
  end

  def create_client_document(input_document, client) do
    if id = Map.get(input_document, :id) do
      document = Repo.get!(Document, id)
      changeset = Document.changeset(document, input_document)

      {:ok, Repo.update!(changeset) |> Repo.preload(@document_preloads)}
    else
      changeset = Document.changeset(%Document{}, input_document)
      created_document = Repo.insert!(changeset) |> Repo.preload(@document_preloads)

      client_document_changeset =
        ClientDocument.changeset(%ClientDocument{}, %{
          client: client,
          document: created_document
        })

      _client_document_records = Repo.insert!(client_document_changeset)

      {:ok, created_document}
    end
  end

  def create_anonymous_document(input_document) do
    if id = Map.get(input_document, :id) do
      document = Repo.get!(Document, id)
      changeset = Document.changeset(document, input_document)

      {:ok, Repo.update!(changeset) |> Repo.preload(@document_preloads)}
    else
      changeset = Document.changeset(%Document{}, input_document)
      created_document = Repo.insert!(changeset) |> Repo.preload(@document_preloads)
      {:ok, created_document}
    end
  end

  def create_for_client_partner_user_and_country(client_id, partner_id, user_id, country_id) do
    inserted_and_updated_at =
      NaiveDateTime.utc_now()
      |> NaiveDateTime.truncate(:second)

    documents =
      Repo.all(
        from dt in DocumentTemplate,
          where:
            dt.client_id == ^client_id and
              (is_nil(dt.partner_id) or dt.partner_id == ^partner_id) and
              (is_nil(dt.country_id) or dt.country_id == ^country_id)
      )
      |> Enum.map(fn dt ->
        %{
          action: dt.action,
          document_template_id: dt.id,
          document_template_category_id: dt.document_template_category_id,
          example_file_url: dt.example_file_url,
          example_filename: dt.example_filename,
          file_type: dt.file_type,
          inserted_at: inserted_and_updated_at,
          updated_at: inserted_and_updated_at
        }
      end)

    # TODO: figure out alternate key(s) to prevent multiple document
    # inserts. Perhaps some "alternate" identifier can be used
    # for this purpose. So for now the on_conflict check does nothing as
    # there are no unique indices
    Multi.new()
    |> Multi.insert_all(:documents, Document, documents, on_conflict: :nothing, returning: true)
    |> Multi.insert_all(
      :user_documents,
      UserDocument,
      fn %{documents: {_, documents}} ->
        Enum.map(documents, fn document ->
          %{
            document_id: document.id,
            user_id: user_id,
            inserted_at: inserted_and_updated_at,
            updated_at: inserted_and_updated_at
          }
        end)
        |> List.flatten()
      end,
      on_conflict: :nothing
    )
    |> Repo.transaction()
  end

  def delete_s3_metadata(document, status) do
    changeset =
      Document.changeset(document, %{
        original_filename: nil,
        original_mime_type: nil,
        status: status
      })

    {:ok, Repo.update!(changeset) |> Repo.preload(@document_preloads)}
  end

  def delete_document(id) do
    Repo.delete(%Document{id: id})
  end

  def delete_document_template(id) do
    Repo.delete(%DocumentTemplate{id: id})
  end

  def all do
    Document |> Repo.all() |> Repo.preload(@document_preloads)
  end

  def all_by_user(user = %User{}) do
    query =
      from(d in Document,
        left_join: ud in UserDocument,
        on: ud.document_id == d.id,
        left_join: u in User,
        on: u.id == ud.user_id,
        where: u.id == ^user.id
      )

    Repo.all(query) |> Repo.preload(@document_preloads)
  end

  def all_by_client(client = %Client{}) do
    query =
      from(d in Document,
        left_join: cd in ClientDocument,
        on: cd.document_id == d.id,
        left_join: c in Client,
        on: c.id == cd.client_id,
        where: c.id == ^client.id
      )

    Repo.all(query) |> Repo.preload(@document_preloads)
  end

  def get_by(keyword) do
    Repo.get_by(Document, keyword)
  end

  def preloads(nil) do
    nil
  end

  def preloads(data) do
    Repo.preload(data, @document_preloads)
  end

  def template_categories_get_by_type(entity_type) do
    query =
      from(d in DocumentTemplateCategory,
        where: d.entity_type == ^entity_type,
        order_by: [asc: :slug]
      )

    Repo.all(query)
  end

  def template_get_by(keyword) do
    Repo.get_by(DocumentTemplate, keyword)
  end

  def template_preloads(nil) do
    nil
  end

  def template_preloads(data) do
    Repo.preload(data, @document_template_preloads)
  end

  def templates_report(
        page_size,
        sort_column,
        sort_direction,
        last_id,
        last_value,
        filter_by,
        search_by
      ) do
    query =
      templates_report_query(
        sort_column,
        sort_direction,
        last_id,
        last_value,
        filter_by,
        search_by
      )

    query = Query.limit(query, ^page_size)
    Repo.all(query)
  end

  def templates_report_query(
        sort_column,
        sort_direction,
        last_id,
        last_value,
        filter_by,
        search_by
      ) do
    last_record_clause =
      build_last_record_clause(last_id, last_value, sort_column, sort_direction)

    order_by_clause = build_order_by_clause(sort_column, sort_direction)
    filter_clause = build_filter_clause(filter_by)
    search_clause = build_search_clause(search_by)

    from dt in DocumentTemplate,
      as: :document_template,
      left_join: dtc in DocumentTemplateCategory,
      as: :document_template_category,
      on: dt.document_template_category_id == dtc.id,
      left_join: p in Partner,
      as: :partner,
      on: dt.partner_id == p.id,
      left_join: c in Client,
      as: :client,
      on: c.id == dt.client_id,
      left_join: cn in Country,
      as: :country,
      on: cn.id == dt.country_id,
      where: ^last_record_clause,
      where: ^filter_clause,
      where: ^search_clause,
      order_by: ^order_by_clause,
      select: %{
        id: dt.id,
        name: dt.name,
        file_type: dt.file_type,
        example_file_mime_type: dt.example_file_mime_type,
        action: dt.action,
        instructions: dt.instructions,
        example_filename: dt.example_filename,
        required: dt.required,
        document_template_category_name: dtc.slug,
        document_template_category_id: dtc.id,
        partner_name: p.name,
        partner_id: p.id,
        client_name: c.name,
        client_id: c.id,
        country_iso_three: cn.iso_alpha_3_code,
        country_name: cn.name,
        country_id: cn.id,
        sql_row_count: fragment("count(*) over()")
      }
  end

  defp build_last_record_clause(0, _last_value, _sort_column, _sort_direction) do
    dynamic(true)
  end

  defp build_last_record_clause(last_id, last_value, sort_column, sort_direction) do
    cond do
      Enum.member?([:name], sort_column) ->
        last_record_clause(sort_direction, :document_template, sort_column, last_id, last_value)

      Enum.member?([:client_name], sort_column) ->
        last_record_clause(sort_direction, :client, sort_column, last_id, last_value)

      Enum.member?([:country_name], sort_column) ->
        last_record_clause(sort_direction, :country, sort_column, last_id, last_value)
    end
  end

  defp last_record_clause(sort_direction, table, sort_column, last_id, last_value) do
    if sort_direction == :asc do
      dynamic(
        [{^table, x}],
        field(x, ^sort_column) > ^last_value or
          (field(x, ^sort_column) == ^last_value and x.id > ^last_id)
      )
    else
      dynamic(
        [{^table, x}],
        field(x, ^sort_column) < ^last_value or
          (field(x, ^sort_column) == ^last_value and x.id > ^last_id)
      )
    end
  end

  defp build_order_by_clause(:client_name, sort_direction) do
    [{sort_direction, dynamic([client: c], c.name)}, asc: :id]
  end

  defp build_order_by_clause(:country_name, sort_direction) do
    [{sort_direction, dynamic([country: cn], cn.name)}, asc: :id]
  end

  defp build_order_by_clause(:country_iso_three, sort_direction) do
    [{sort_direction, dynamic([country: cn], cn.iso_alpha_3_code)}, asc: :id]
  end

  defp build_order_by_clause(:document_template_category_name, sort_direction) do
    [{sort_direction, dynamic([document_template_category: dtc], dtc.slug)}, asc: :id]
  end

  defp build_order_by_clause(:name, sort_direction) do
    [{sort_direction, dynamic([document_template: dt], dt.name)}, asc: :id]
  end

  defp build_order_by_clause(:required_string, sort_direction) do
    [{sort_direction, dynamic([document_template: dt], dt.required)}, asc: :id]
  end

  defp build_order_by_clause(:partner_name, sort_direction) do
    [{sort_direction, dynamic([partner: p], p.name)}, asc: :id]
  end

  defp build_order_by_clause(sort_column, sort_direction) do
    [{sort_direction, sort_column}, asc: :id]
  end

  defp build_filter_clause(filter_by) do
    Enum.reduce(filter_by, dynamic(true), fn filter, filter_clause ->
      where_clause = build_filter_where_clause(Macro.underscore(filter.name), filter.value)
      dynamic([u, c, a, cn], ^filter_clause and ^where_clause)
    end)
  end

  defp build_filter_where_clause("client_id", value) do
    client_ids = String.split(value, ",")
    dynamic([client: c], c.id in ^client_ids)
  end

  defp build_filter_where_clause("client_name", value) do
    filter_value = "%#{value}%"
    dynamic([client: c], like(c.name, ^filter_value))
  end

  defp build_filter_where_clause("country_id", value) do
    country_ids = String.split(value, ",")
    dynamic([country: cn], cn.id in ^country_ids)
  end

  defp build_filter_where_clause("region_id", value) do
    region_ids = String.split(value, ",")
    dynamic([region: r], r.id in ^region_ids)
  end

  defp build_filter_where_clause("country_name", value) do
    filter_value = "%#{value}%"
    dynamic([country: cn], like(cn.name, ^filter_value))
  end

  defp build_filter_where_clause("partner_id", value) do
    partner_ids = String.split(value, ",")
    dynamic([partner: p], p.id in ^partner_ids)
  end

  defp build_filter_where_clause("document_template_category_id", value) do
    document_template_category_ids = String.split(value, ",")
    dynamic([document_template_category: dtc], dtc.id in ^document_template_category_ids)
  end

  defp build_filter_where_clause("action", value) do
    actions = String.split(value, ",")
    dynamic([document_template: dt], dt.action in ^actions)
  end

  defp build_search_clause(search_by) do
    if search_by != nil && String.trim(search_by) != "" do
      search_by_value = "#{String.trim(search_by)}:*"

      dynamic(
        [document_template: dt],
        fragment("to_tsvector(?) @@ plainto_tsquery(?)", dt.name, ^search_by_value)
      )
    else
      dynamic(true)
    end
  end
end
