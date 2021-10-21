defmodule VelocityWeb.Resolvers.Documents do
  @moduledoc """
  GQL resolver for documenst
  """

  alias ExAws.S3
  alias Velocity.Contexts.Clients
  alias Velocity.Contexts.Documents
  alias Velocity.Contexts.Docusign
  alias Velocity.Contexts.Users
  alias Velocity.Repo
  alias Velocity.Schema.ClientDocument
  alias Velocity.Schema.Document
  alias Velocity.Schema.User
  alias Velocity.Schema.UserDocument

  def templates_report(args, _) do
    document_templates =
      Documents.templates_report(
        args.page_size,
        String.to_atom(Macro.underscore(args.sort_column)),
        String.to_atom(args.sort_direction),
        args.last_id,
        args.last_value,
        args.filter_by,
        args.search_by
      )

    row_count =
      if Enum.count(document_templates) > 0 do
        Enum.at(document_templates, 0)[:sql_row_count]
      else
        0
      end

    {:ok, %{row_count: row_count, document_templates: document_templates}}
  end

  def get_template(%{id: document_template_id}, _) do
    {:ok,
     [id: document_template_id] |> Documents.template_get_by() |> Documents.template_preloads()}
  end

  def document_template_upload(_, _) do
    s3_key = Ecto.UUID.generate()

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
  end

  def all(_, %{context: %{current_user: current_user}}) do
    if Users.is_user_internal(current_user) do
      {:ok, Documents.all()}
    else
      {:error, "Current user is not authorized to view documents"}
    end
  end

  def all_for_current_user(_, %{context: %{current_user: current_user}}) do
    {:ok, Documents.all_by_user(current_user)}
  end

  def all_for_user(_args = %{user_id: user_id}, %{context: %{current_user: current_user}}) do
    # TODO: add permissions/asignments check to make sure the user asking can get this info
    if Users.is_user_internal(current_user) do
      user = Users.get_by(id: user_id)
      {:ok, Documents.all_by_user(user)}
    else
      {:error, "Current user is not authorized to view documents for user #{user_id}"}
    end
  end

  def all_for_client(_args = %{client_id: client_id}, %{context: %{current_user: current_user}}) do
    # TODO: add permissions/asignments check to make sure the user asking can get this info
    if Users.is_user_internal(current_user) do
      client = Clients.get_by(id: client_id)
      {:ok, Documents.all_by_client(client)}
    else
      {:error, "Current user is not authorized to view documents for client #{client_id}"}
    end
  end

  def get(%{id: document_id}, %{context: %{current_user: current_user}}) do
    # TODO: add permissions/asignments check to make sure the user asking can get this info
    if Users.is_user_internal(current_user) do
      {:ok, [id: document_id] |> Documents.get_by() |> Documents.preloads()}
    else
      {:error, "Current user is not authorized to view document #{document_id}"}
    end
  end

  def save_user_document(args, %{context: %{current_user: current_user}}) do
    case Documents.get_by(id: args.document_id) do
      nil ->
        {:error, "document not found"}

      document ->
        user_document = Repo.get_by(UserDocument, %{document_id: document.id})
        # TODO: add permissions/asignments check to make sure the user can take this action
        if user_document.user_id == current_user.id || Users.is_user_internal(current_user) do
          changeset = Document.changeset(document, args)

          {:ok, Repo.update!(changeset) |> Documents.preloads()}
        else
          {:error, "Current user is not authorized to change document #{document.id}"}
        end
    end
  end

  def save_client_document(args, %{context: %{current_user: current_user}}) do
    case Documents.get_by(id: args.document_id) do
      nil ->
        {:error, "document not found"}

      document ->
        # TODO: add permissions/asignments check to make sure the user can take this action
        if Users.is_user_internal(current_user) do
          changeset = Document.changeset(document, args)

          {:ok, Repo.update!(changeset) |> Documents.preloads()}
        else
          {:error, "Current user is not authorized to change document #{document.id}"}
        end
    end
  end

  def categories_by_type(_args = %{entity_type: entity_type}, _) do
    template_categories = Documents.template_categories_get_by_type(entity_type)
    {:ok, template_categories}
  end

  # credo:disable-for-lines:47 Credo.Check.Refactor.CyclomaticComplexity
  def save_user_documents(args, %{context: %{current_user: current_user}}) do
    result =
      Enum.reduce_while(args.documents, {:ok, []}, fn input_document, acc ->
        # first, check for input errors
        # TODO: would it be better to just swallow errors and update everything we can?
        existing_document = Repo.get(Document, Map.get(input_document, :id) || 0)

        cond do
          !Map.has_key?(input_document, :id) || input_document.id == nil ->
            error = {:error, "id is required for each document"}
            {:halt, error}

          existing_document == nil ->
            error = {:error, "document with id #{input_document.id} does not exist"}
            {:halt, error}

          !(Repo.get_by(UserDocument, %{document_id: existing_document.id}).user_id ==
              current_user.id || Users.is_user_internal(current_user)) ->
            error =
              {:error,
               "User #{current_user.id} is not authorized to update document #{
                 existing_document.id
               }"}

            {:halt, error}

          true ->
            changeset = Document.changeset(existing_document, input_document)
            other_changesets = elem(acc, 1)
            acc = {:ok, [changeset | other_changesets]}
            {:cont, acc}
        end
      end)

    case result do
      {:error, message} ->
        {:error, message}

      {:ok, changesets} ->
        # If no input errors, update all passed docs
        updated_docs =
          Enum.map(changesets, fn changeset ->
            {:ok, updated_doc} = Repo.update(changeset)
            updated_doc
          end)

        {:ok, updated_docs}
    end
  end

  # credo:disable-for-lines:47 Credo.Check.Refactor.CyclomaticComplexity
  def save_client_documents(args, %{context: %{current_user: current_user}}) do
    result =
      Enum.reduce_while(args.documents, {:ok, []}, fn input_document, acc ->
        # first, check for input errors
        # TODO: would it be better to just swallow errors and update everything we can?
        existing_document = Repo.get(Document, Map.get(input_document, :id) || 0)

        cond do
          !Map.has_key?(input_document, :id) || input_document.id == nil ->
            error = {:error, "id is required for each document"}
            {:halt, error}

          existing_document == nil ->
            error = {:error, "document with id #{input_document.id} does not exist"}
            {:halt, error}

          !Users.is_user_internal(current_user) ->
            error =
              {:error,
               "User #{current_user.id} is not authorized to update document #{
                 existing_document.id
               }"}

            {:halt, error}

          true ->
            changeset = Document.changeset(existing_document, input_document)
            other_changesets = elem(acc, 1)
            acc = {:ok, [changeset | other_changesets]}
            {:cont, acc}
        end
      end)

    case result do
      {:error, message} ->
        {:error, message}

      {:ok, changesets} ->
        # If no input errors, update all passed docs
        updated_docs =
          Enum.map(changesets, fn changeset ->
            {:ok, updated_doc} = Repo.update(changeset)
            updated_doc
          end)

        {:ok, updated_docs}
    end
  end

  def create_user_documents(args, %{context: %{current_user: current_user}}) do
    if args.user_id == to_string(current_user.id) || Users.is_user_internal(current_user) do
      created_docs =
        Enum.map(args.documents, fn input_document ->
          {:ok, created_doc} =
            Documents.create_user_document(input_document, Users.get_by(id: args.user_id))

          created_doc
        end)

      {:ok, created_docs}
    else
      {:error,
       "User #{current_user.id} is not authorized to create document for user #{args.user_id}"}
    end
  end

  def create_client_documents(args, %{context: %{current_user: current_user}}) do
    if Users.is_user_internal(current_user) do
      created_docs =
        Enum.map(args.documents, fn input_document ->
          {:ok, created_doc} =
            Documents.create_client_document(input_document, Clients.get_by(id: args.client_id))

          created_doc
        end)

      {:ok, created_docs}
    else
      {:error,
       "User #{current_user.id} is not authorized to create document for client #{args.client_id}"}
    end
  end

  def create_anonymous_documents(args, %{context: %{current_user: current_user}}) do
    if Users.is_user_internal(current_user) do
      created_docs =
        Enum.map(args.documents, fn input_document ->
          {:ok, created_doc} = Documents.create_anonymous_document(input_document)

          created_doc
        end)

      {:ok, created_docs}
    else
      {:error, "User #{current_user.id} is not authorized to create anonymous documents"}
    end
  end

  def upsert_document_template(args, _) do
    Documents.upsert_document_template(args)
  end

  def delete_user_s3_metadata(args, %{context: %{current_user: current_user}}) do
    case Documents.get_by(id: args.id) do
      nil ->
        {:error, "document not found"}

      document ->
        user_document = Repo.get_by(UserDocument, %{document_id: document.id})
        # TODO: add permissions/asignments check to make sure the user can take this action
        if user_document.user_id == current_user.id || Users.is_user_internal(current_user) do
          Documents.delete_s3_metadata(document, args.status)
        else
          {:error, "Current user is not authorized to view document #{document.id}"}
        end
    end
  end

  def delete_client_s3_metadata(args, %{context: %{current_user: current_user}}) do
    case Documents.get_by(id: args.id) do
      nil ->
        {:error, "document not found"}

      document ->
        # TODO: add permissions/asignments check to make sure the user can take this action
        if Users.is_user_internal(current_user) do
          Documents.delete_s3_metadata(document, args.status)
        else
          {:error, "Current user is not authorized to view document #{document.id}"}
        end
    end
  end

  def delete_user_document(args, %{context: %{current_user: current_user}}) do
    document = Repo.get!(Document, args.id)
    user_document = Repo.get_by(UserDocument, %{document_id: document.id})

    if user_document.user_id == current_user.id || Users.is_user_internal(current_user) do
      Repo.delete(%UserDocument{id: user_document.id})
      Documents.delete_document(String.to_integer(args.id))
    else
      {:error, "User #{current_user.id} is not authorized to delete document #{document.id}"}
    end
  end

  def delete_client_document(args, %{context: %{current_user: current_user}}) do
    document = Repo.get!(Document, args.id)
    client_document = Repo.get_by(ClientDocument, %{document_id: document.id})

    if Users.is_user_internal(current_user) do
      Repo.delete(%ClientDocument{id: client_document.id})
      Documents.delete_document(String.to_integer(args.id))
    else
      {:error, "User #{current_user.id} is not authorized to delete document #{document.id}"}
    end
  end

  def delete_document_template(args, _) do
    Documents.delete_document_template(String.to_integer(args.id))
  end

  def docusign_signing_url(args, %{context: %{current_user: current_user}}) do
    document = Repo.get!(Document, args.document_id)
    user_document = Repo.get_by(UserDocument, %{document_id: document.id})
    user = if is_nil(user_document), do: nil, else: Repo.get!(User, user_document.user_id)

    cond do
      user_document == nil || user_document.user_id == nil ->
        {:error, "No user assigned to document_id #{document.id}"}

      document.docusign_template_id == nil ->
        {:error, "No docusign template set for document_id #{document.id}"}

      user_document.user_id != current_user.id ->
        {:error, "Current user is not assigned to document_id #{document.id}"}

      true ->
        # No validation errors
        Docusign.signing_url(document, user, args.redirect_uri)
    end
  end

  def docusign_recipient_view_url(args, %{context: %{current_user: current_user}}) do
    document = Repo.get!(Document, args.document_id)

    # User has permissions if internal or external and assigned to the doc
    user_document = Repo.get_by(UserDocument, %{document_id: document.id})
    user = if is_nil(user_document), do: nil, else: Repo.get!(User, user_document.user_id)

    has_doc_permissions =
      Users.is_user_internal(current_user) || user_document.user_id == current_user.id

    cond do
      user_document == nil || user_document.user_id == nil ->
        {:error, "No user assigned to document_id #{document.id}"}

      document.docusign_envelope_id == nil ->
        {:error, "No docusign envelope generated yet for document_id #{document.id}"}

      document.status != "completed" ->
        {:error, "The document_id #{document.id} has not yet been signed"}

      !has_doc_permissions ->
        {:error, "Current user lacks permissions to access document_id #{document.id}"}

      true ->
        # No validation errors
        Docusign.recipient_view_url(document, user, args.redirect_uri)
    end
  end
end
