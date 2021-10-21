defmodule VelocityWeb.Schema.DocumentTypes do
  @moduledoc false
  use Absinthe.Schema.Notation

  alias ExAws.S3
  alias Velocity.Repo
  alias Velocity.Schema.Document

  object :document_template_category do
    field(:id, :id)
    field(:slug, :string)
  end

  @desc "document template"
  object :document_template do
    field :id, :id
    field :name, :string
    field :file_type, :string
    field :client, :client
    field :country, :country
    field :document_template_category, :document_template_category
    field :document_template_category_id, :id
    field :action, :string
    field :instructions, :string
    field :example_file_mime_type, :string
    field :example_file_url, :id
    field :example_filename, :string
    field :required, :boolean
    field :partner_id, :id
    field :client_id, :id
    field :country_id, :id

    field :s3_upload, :s3_upload do
      resolve(fn document_template, _, _ ->
        s3_key =
          if document_template.example_file_url != nil do
            document_template.example_file_url
          else
            Ecto.UUID.generate()
          end

        {:ok, presigned} =
          S3.presigned_url(
            ExAws.Config.new(:s3),
            :put,
            Application.get_env(:velocity, :s3_bucket),
            s3_key,
            virtual_host: true
          )

        {:ok, presigned_delete_url} =
          S3.presigned_url(
            ExAws.Config.new(:s3),
            :delete,
            Application.get_env(:velocity, :s3_bucket),
            s3_key,
            virtual_host: true
          )

        {:ok,
         %{
           presigned_url: presigned,
           s3_key: s3_key,
           presigned_delete_url: presigned_delete_url
         }}
      end)
    end
  end

  @desc "document template for the report table"
  object :report_document_template do
    field :id, :id
    field :name, :string
    field :file_type, :string
    field :action, :string
    field :instructions, :string
    field :example_file_mime_type, :string
    field :example_file_url, :id
    field :example_filename, :string
    field :required, :boolean
    field :document_template_category_id, :id
    field :document_template_category_name, :string
    field :partner_name, :string
    field :partner_id, :id
    field :client_name, :string
    field :client_id, :id
    field :country_iso_three, :string
    field :country_name, :string
    field :country_id, :id

    field(:required_string, :string) do
      resolve(fn document_template, _args, _info ->
        required =
          case document_template.required do
            true -> "Y"
            false -> "N"
            nil -> "N"
          end

        {:ok, required}
      end)
    end
  end

  @desc "paginated document templates"
  object :paginated_document_templates_report do
    field :row_count, :integer
    field :document_templates, list_of(:report_document_template)
  end

  @desc "document"
  object :document do
    field(:id, :id)
    field(:name, :string)
    field(:file_type, :string)
    field(:original_filename, :string)
    field(:original_mime_type, :string)
    field(:document_template, :document_template)
    field(:docusign_template_id, :string)

    field(:country, :country) do
      resolve(fn document, _args, _info ->
        document = Repo.preload(document, document_template: :country)
        {:ok, document.document_template.country}
      end)
    end

    field(:status, :string)

    field :url, :string do
      resolve(fn document, _, _ ->
        if document.s3_key != nil do
          S3.presigned_url(
            ExAws.Config.new(:s3),
            :get,
            Application.get_env(:velocity, :s3_bucket),
            document.s3_key,
            virtual_host: true
          )
        else
          {:ok, nil}
        end
      end)
    end

    field :example_file_url, :string do
      resolve(fn document, _, _ ->
        cond do
          document.example_file_url != nil ->
            S3.presigned_url(
              ExAws.Config.new(:s3),
              :get,
              Application.get_env(:velocity, :s3_bucket),
              document.example_file_url,
              query_params: [
                "response-content-disposition":
                  "attachment; filename=#{document.example_filename || document.name}"
              ],
              virtual_host: true
            )

          Ecto.assoc_loaded?(document.document_template) && document.document_template &&
              document.document_template.example_file_url != nil ->
            S3.presigned_url(
              ExAws.Config.new(:s3),
              :get,
              Application.get_env(:velocity, :s3_bucket),
              document.document_template.example_file_url,
              query_params: [
                "response-content-disposition":
                  "attachment; filename=#{
                    document.document_template.example_filename || document.name
                  }"
              ],
              virtual_host: true
            )

          true ->
            {:ok, nil}
        end
      end)
    end

    field :download_url, :string do
      resolve(fn document, _, _ ->
        if document.s3_key do
          S3.presigned_url(
            ExAws.Config.new(:s3),
            :get,
            Application.get_env(:velocity, :s3_bucket),
            document.s3_key,
            query_params: [
              "content-type": document.original_mime_type,
              "response-content-type": document.original_mime_type,
              "response-content-disposition": "attachment; filename=#{document.original_filename}"
            ],
            virtual_host: true
          )
        else
          {:ok, nil}
        end
      end)
    end

    field(:category, :string) do
      resolve(fn document, _args, _info ->
        cond do
          document.document_template_category_id != nil ->
            document = Repo.preload(document, :document_template_category)
            {:ok, document.document_template_category.slug}

          Ecto.assoc_loaded?(document.document_template) &&
            document.document_template &&
              document.document_template.document_template_category_id != nil ->
            document = Repo.preload(document, document_template: :document_template_category)
            {:ok, document.document_template.document_template_category.slug}

          true ->
            {:ok, ""}
        end
      end)
    end

    field(:action, :string) do
      resolve(fn document, _args, _info ->
        cond do
          document.action != nil ->
            {:ok, document.action}

          Ecto.assoc_loaded?(document.document_template) && document.document_template &&
              document.document_template.action != nil ->
            {:ok, document.document_template.action}

          true ->
            {:ok, ""}
        end
      end)
    end

    field(:mime_type, :string) do
      resolve(fn document, _args, _info ->
        cond do
          document.original_mime_type != nil ->
            mime_type = document.original_mime_type
            {:ok, mime_type}

          Ecto.assoc_loaded?(document.document_template) && document.document_template &&
              document.document_template.example_file_mime_type != nil ->
            mime_type = document.document_template.example_file_mime_type
            {:ok, mime_type}

          true ->
            {:ok, ""}
        end
      end)
    end

    field :s3_upload, :s3_upload do
      resolve(fn document, _, _ ->
        cond do
          (Ecto.assoc_loaded?(document.document_template) &&
             (document.document_template &&
                document.document_template.action != "sign")) || document.s3_key ->
            document_with_uuid =
              if document.s3_key != nil do
                document
              else
                changeset = Document.changeset(document, %{s3_key: Ecto.UUID.generate()})

                Repo.update!(changeset)
              end

            {:ok, presigned} =
              S3.presigned_url(
                ExAws.Config.new(:s3),
                :put,
                Application.get_env(:velocity, :s3_bucket),
                document_with_uuid.s3_key,
                virtual_host: true
              )

            {:ok, presigned_delete_url} =
              S3.presigned_url(
                ExAws.Config.new(:s3),
                :delete,
                Application.get_env(:velocity, :s3_bucket),
                document_with_uuid.s3_key,
                virtual_host: true
              )

            {:ok,
             %{
               presigned_url: presigned,
               s3_key: document_with_uuid.s3_key,
               presigned_delete_url: presigned_delete_url
             }}

          (Ecto.assoc_loaded?(document.document_template) &&
             (document.document_template &&
                document.document_template.action == "sign")) || document.action == "sign" ->
            {:ok, %{presigned_url: nil, s3_key: document.s3_key, presigned_delete_url: nil}}

          true ->
            {:ok, %{}}
        end
      end)
    end
  end

  @desc "upload"
  object :s3_upload do
    field(:presigned_url, :string)
    field(:presigned_delete_url, :string)
    field(:s3_key, :string)
  end

  input_object :input_document do
    field :id, :id
    field :user_id, :id
    field :s3_key, :id
    field :action, :string
    field :name, :string
    field :original_filename, :string
    field :original_mime_type, :string
    field :file_type, :string
    field :status, :string
    field :docusign_template_id, :string
    field :document_template_category_id, :id
  end
end
