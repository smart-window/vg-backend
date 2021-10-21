defmodule VelocityWeb.Resolvers.DocumentsTest do
  use VelocityWeb.ConnCase, async: true

  alias Velocity.Repo
  alias Velocity.Schema.ClientDocument
  alias Velocity.Schema.Document
  alias Velocity.Schema.UserDocument

  @documents_query """
    query Documents {
      documents {
        id
        documentTemplate {
          exampleFileMimeType
          action
        }
        country {
          name
        }
        status
        url
      }
    }
  """

  describe "query :documents" do
    test "it returns all documents", %{conn: conn} do
      admin_user = Factory.insert(:user)
      admin_group = Factory.insert(:group, %{slug: "admin", okta_group_slug: "PegaAdmins"})
      Factory.insert(:user_group, %{user_id: admin_user.id, group_id: admin_group.id})

      country = Factory.insert(:country)
      template = Factory.insert(:document_template, %{country_id: country.id})
      Factory.insert_list(5, :document, %{document_template_id: template.id})

      %{"data" => %{"documents" => documents}} =
        conn
        |> put_req_header("test-only-okta-user-uid", admin_user.okta_user_uid)
        |> post("/graphql", %{
          query: @documents_query
        })
        |> json_response(200)

      assert Enum.count(documents) == 5
    end
  end

  @documents_for_current_user_query """
    query CurrentUserDocuments {
      currentUserDocuments {
        id
        documentTemplate {
          exampleFileMimeType
          action
        }
        country {
          name
        }
        status
        url
      }
    }
  """

  describe "query :current_user_documents" do
    test "it returns all documents for current user", %{conn: conn} do
      user = Factory.insert(:user)
      country = Factory.insert(:country)
      template = Factory.insert(:document_template, %{country_id: country.id})
      Factory.insert_list(5, :document, %{document_template_id: template.id})
      document = Factory.insert(:document, %{document_template_id: template.id})
      Factory.insert(:user_document, %{document_id: document.id, user_id: user.id})

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @documents_for_current_user_query
        })
        |> json_response(200)

      assert Enum.count(response["data"]["currentUserDocuments"]) == 1
    end
  end

  @documents_for_user_query """
    query UserDocuments($userId: ID!) {
      userDocuments(userId: $userId) {
        id
        documentTemplate {
          exampleFileMimeType
          action
        }
        country {
          name
        }
        status
        url
      }
    }
  """

  describe "query :user_documents" do
    test "it returns all documents for a provided user", %{conn: conn} do
      user = Factory.insert(:user)
      admin_user = Factory.insert(:user)
      admin_group = Factory.insert(:group, %{slug: "admin", okta_group_slug: "PegaAdmins"})
      Factory.insert(:user_group, %{user_id: admin_user.id, group_id: admin_group.id})

      country = Factory.insert(:country)
      template = Factory.insert(:document_template, %{country_id: country.id})
      Factory.insert_list(5, :document, %{document_template_id: template.id})
      document = Factory.insert(:document, %{document_template_id: template.id})
      Factory.insert(:user_document, %{document_id: document.id, user_id: user.id})

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", admin_user.okta_user_uid)
        |> post("/graphql", %{
          query: @documents_for_user_query,
          variables: %{
            userId: user.id
          }
        })
        |> json_response(200)

      assert Enum.count(response["data"]["userDocuments"]) == 1
    end
  end

  @document_templates_query """
    query DocumentTemplatesReport($pageSize: Int, $sortColumn: String, $sortDirection: String, $filterBy: [FilterBy], $searchBy: String) {
      documentTemplatesReport(pageSize: $pageSize, sortColumn: $sortColumn, sortDirection: $sortDirection, filterBy: $filterBy, searchBy: $searchBy) {
        row_count
        documentTemplates {
          id
          name
          exampleFileMimeType
          action
          instructions
          exampleFileUrl
        }
      }
    }
  """
  describe "query :documentTemplates" do
    test "it returns all document templates", %{conn: conn} do
      Factory.insert_list(5, :document_template)

      %{"data" => %{"documentTemplatesReport" => %{"documentTemplates" => document_templates}}} =
        conn
        |> put_req_header("test-only-okta-user-uid", "fake")
        |> post("/graphql", %{
          query: @document_templates_query,
          variables: %{
            pageSize: 5,
            sortColumn: "name",
            sortDirection: "asc"
          }
        })
        |> json_response(200)

      assert Enum.count(document_templates) == 5
    end

    test "it sorts correctly", %{conn: conn} do
      Enum.map(1..5, fn index ->
        Factory.insert(:document_template, name: "#{index}")
      end)

      %{"data" => %{"documentTemplatesReport" => %{"documentTemplates" => document_templates}}} =
        conn
        |> put_req_header("test-only-okta-user-uid", "fake")
        |> post("/graphql", %{
          query: @document_templates_query,
          variables: %{
            pageSize: 5,
            sortColumn: "name",
            sortDirection: "asc"
          }
        })
        |> json_response(200)

      template_names = Enum.map(document_templates, & &1["name"])
      sorted_template_names = Enum.sort(template_names)

      assert List.first(document_templates)["name"] == List.first(sorted_template_names)
      assert List.last(document_templates)["name"] == List.last(sorted_template_names)
    end
  end

  @document_query """
    query Document($id: ID!) {
      document(id: $id) {
        id
        action
        status
        url
        downloadUrl
        documentTemplate {
          exampleFileMimeType
          action
        }
        country {
          name
        }
      }
    }
  """
  describe "query :document" do
    test "it returns a specific document", %{conn: conn} do
      admin_user = Factory.insert(:user)
      admin_group = Factory.insert(:group, %{slug: "admin", okta_group_slug: "PegaAdmins"})
      Factory.insert(:user_group, %{user_id: admin_user.id, group_id: admin_group.id})

      country = Factory.insert(:country)
      template = Factory.insert(:document_template, %{country_id: country.id, action: "upload"})

      [document | _] =
        Factory.insert_list(5, :document, %{document_template_id: template.id, action: "download"})

      %{"data" => %{"document" => %{"id" => id, "action" => action}}} =
        conn
        |> put_req_header("test-only-okta-user-uid", admin_user.okta_user_uid)
        |> post("/graphql", %{
          query: @document_query,
          variables: %{
            id: document.id
          }
        })
        |> json_response(200)

      assert id == Integer.to_string(document.id)
      assert action == "download"
    end
  end

  @delete_user_s3_metadata """
    mutation DeleteUserS3Metadata($id: ID!, $status: String!) {
      deleteUserS3Metadata(id: $id, status: $status) {
        id
        status
      }
    }
  """
  describe "mutation :delete_user_s3_metadata" do
    test "it deletes a specific document's s3 metadata", %{conn: conn} do
      user = Factory.insert(:user)
      country = Factory.insert(:country)
      template = Factory.insert(:document_template, %{country_id: country.id})

      document =
        Factory.insert(:document, %{
          document_template_id: template.id,
          s3_key: "12345123",
          original_filename: "testdoc.jpg",
          original_mime_type: "image/jpeg",
          status: "completed"
        })

      Factory.insert(:user_document, %{document_id: document.id, user_id: user.id})

      status = "not_started"

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @delete_user_s3_metadata,
          variables: %{
            id: document.id,
            status: status
          }
        })
        |> json_response(200)

      updated_doc = Repo.get(Document, response["data"]["deleteUserS3Metadata"]["id"])
      assert updated_doc.status == status
      assert updated_doc.original_filename == nil
    end
  end

  # @save_user_document """
  #   mutation saveUserDocument(
  #     $documentId: ID!
  #     $s3Key: ID
  #     $originalFilename: String
  #     $originalMimeType: String
  #     $status: String
  #     $fileType: String
  #     $docusignTemplateId: String
  #   ) {
  #     saveUserDocument(
  #       documentId: $documentId
  #       s3Key: $s3Key
  #       originalFilename: $originalFilename
  #       originalMimeType: $originalMimeType
  #       status: $status
  #       fileType: $fileType
  #       docusignTemplateId: $docusignTemplateId
  #     ) {
  #       id
  #       name
  #       status
  #       mimeType
  #       fileType
  #       docusignTemplateId
  #       downloadUrl
  #       category
  #       action
  #       exampleFileUrl
  #       originalFilename
  #       originalMimeType
  #       url
  #       s3Upload {
  #         presignedUrl
  #         presignedDeleteUrl
  #         s3Key
  #       }
  #     }
  #   }
  # """

  # describe "mutation :save_user_document" do
  #   test "it saves a specific document's information", %{conn: conn} do
  #     user = Factory.insert(:user)
  #     country = Factory.insert(:country)
  #     template = Factory.insert(:document_template, %{country_id: country.id})

  #     document =
  #       Factory.insert(:document, %{
  #         document_template_id: template.id,
  #         s3_key: "12345123",
  #         original_filename: "testdoc.jpg",
  #         original_mime_type: "image/jpeg",
  #         status: "not_started"
  #       })

  #     Factory.insert(:user_document, %{document_id: document.id, user_id: user.id})

  #     response =
  #       conn
  #       |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
  #       |> post("/graphql", %{
  #         query: @save_user_document,
  #         variables: %{
  #           documentId: document.id,
  #           status: "completed"
  #         }
  #       })
  #       |> json_response(200)

  #     updated_doc = Repo.get(Document, response["data"]["saveUserDocument"]["id"])
  #     assert updated_doc.status == "completed"
  #   end
  # end

  @create_user_documents """
    mutation CreateUserDocuments($documents: [InputDocuments]!, $userId: ID!) {
      createUserDocuments(documents: $documents, userId: $userId) {
        id
      }
    }
  """

  describe "mutation :create_user_documents" do
    test "it creates multiple documents", %{conn: conn} do
      user = Factory.insert(:user)
      admin_user = Factory.insert(:user)
      admin_group = Factory.insert(:group, %{slug: "admin", okta_group_slug: "PegaAdmins"})
      Factory.insert(:user_group, %{user_id: admin_user.id, group_id: admin_group.id})

      doc1 = %{
        s3_key: "12345123",
        original_filename: "testdoc.jpg",
        original_mime_type: "image/jpeg",
        status: "not_started"
      }

      doc2 = %{
        s3_key: "72390874320",
        original_filename: "testdoc2.jpg",
        original_mime_type: "image/jpeg",
        status: "not_started"
      }

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", admin_user.okta_user_uid)
        |> post("/graphql", %{
          query: @create_user_documents,
          variables: %{
            documents: [doc1, doc2],
            userId: user.id
          }
        })
        |> json_response(200)

      assert %{"data" => %{"createUserDocuments" => created_documents}} = response
      assert length(created_documents) == 2
      assert length(Repo.all(UserDocument)) == 2
    end

    test "it fails if the user lacks permissions", %{conn: conn} do
      user1 = Factory.insert(:user)
      user2 = Factory.insert(:user)

      doc1 = %{
        s3_key: "12345123",
        original_filename: "testdoc.jpg",
        original_mime_type: "image/jpeg",
        status: "not_started"
      }

      %{"errors" => errors} =
        conn
        |> put_req_header("test-only-okta-user-uid", user1.okta_user_uid)
        |> post("/graphql", %{
          query: @create_user_documents,
          variables: %{
            documents: [doc1],
            userId: user2.id
          }
        })
        |> json_response(200)

      assert List.first(errors) |> Map.get("message") ==
               "User #{user1.id} is not authorized to create document for user #{user2.id}"
    end
  end

  @create_client_documents """
    mutation CreateClientDocuments($documents: [InputDocuments]!, $clientId: ID!) {
      createClientDocuments(documents: $documents, clientId: $clientId) {
        id
      }
    }
  """

  describe "mutation :create_client_documents" do
    test "it creates multiple documents", %{conn: conn} do
      admin_user = Factory.insert(:user)
      admin_group = Factory.insert(:group, %{slug: "admin", okta_group_slug: "PegaAdmins"})
      Factory.insert(:user_group, %{user_id: admin_user.id, group_id: admin_group.id})

      client = Factory.insert(:client)

      doc1 = %{
        s3_key: "12345123",
        original_filename: "testdoc.jpg",
        original_mime_type: "image/jpeg",
        status: "not_started"
      }

      doc2 = %{
        s3_key: "72390874320",
        original_filename: "testdoc2.jpg",
        original_mime_type: "image/jpeg",
        status: "not_started"
      }

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", admin_user.okta_user_uid)
        |> post("/graphql", %{
          query: @create_client_documents,
          variables: %{
            documents: [doc1, doc2],
            clientId: client.id
          }
        })
        |> json_response(200)

      assert %{"data" => %{"createClientDocuments" => created_documents}} = response
      assert length(created_documents) == 2
      assert length(Repo.all(ClientDocument)) == 2
    end

    test "it fails if the user lacks permissions", %{conn: conn} do
      user = Factory.insert(:user)
      client = Factory.insert(:client)

      doc1 = %{
        s3_key: "12345123",
        original_filename: "testdoc.jpg",
        original_mime_type: "image/jpeg",
        status: "not_started"
      }

      %{"errors" => errors} =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @create_client_documents,
          variables: %{
            documents: [doc1],
            clientId: client.id
          }
        })
        |> json_response(200)

      assert List.first(errors) |> Map.get("message") ==
               "User #{user.id} is not authorized to create document for client #{client.id}"
    end
  end

  @save_user_documents """
    mutation SaveUserDocuments($documents: [InputDocuments]!, $userId: ID!) {
      saveUserDocuments(documents: $documents, userId: $userId) {
        id
        originalFilename
      }
    }
  """
  describe "mutation :save_user_documents" do
    test "it updates multiple documents", %{conn: conn} do
      user = Factory.insert(:user)

      [doc1, doc2] = Factory.insert_list(2, :document, %{original_filename: "123"})

      Factory.insert(:user_document, %{document_id: doc1.id, user_id: user.id})
      Factory.insert(:user_document, %{document_id: doc2.id, user_id: user.id})

      doc1_updates = %{
        id: doc1.id,
        original_filename: "456"
      }

      doc2_updates = %{
        id: doc2.id,
        original_filename: "456"
      }

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @save_user_documents,
          variables: %{
            documents: [doc1_updates, doc2_updates],
            userId: user.id
          }
        })
        |> json_response(200)

      assert %{"data" => %{"saveUserDocuments" => updated_documents}} = response
      assert length(updated_documents) == 2
      assert Map.get(hd(updated_documents), "originalFilename") == "456"
    end

    test "it fails if no document id is passed", %{conn: conn} do
      user = Factory.insert(:user)

      doc_updates = %{
        original_filename: "456"
      }

      %{"errors" => errors} =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @save_user_documents,
          variables: %{
            documents: [doc_updates],
            userId: user.id
          }
        })
        |> json_response(200)

      assert List.first(errors) |> Map.get("message") ==
               "id is required for each document"
    end

    test "it fails if the document does not exist", %{conn: conn} do
      user = Factory.insert(:user)

      doc_updates = %{
        original_filename: "456",
        id: "1234234234"
      }

      %{"errors" => errors} =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @save_user_documents,
          variables: %{
            documents: [doc_updates],
            userId: user.id
          }
        })
        |> json_response(200)

      assert List.first(errors) |> Map.get("message") ==
               "document with id #{doc_updates.id} does not exist"
    end

    test "it fails if the user lacks permissions", %{conn: conn} do
      user = Factory.insert(:user)
      user2 = Factory.insert(:user)
      doc = Factory.insert(:document, %{original_filename: "123"})
      Factory.insert(:user_document, %{document_id: doc.id, user_id: user2.id})

      doc_updates = %{
        original_filename: "456",
        id: doc.id
      }

      %{"errors" => errors} =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @save_user_documents,
          variables: %{
            documents: [doc_updates],
            userId: user2.id
          }
        })
        |> json_response(200)

      assert List.first(errors) |> Map.get("message") ==
               "User #{user.id} is not authorized to update document #{doc.id}"
    end
  end

  @save_client_documents """
    mutation SaveClientDocuments($documents: [InputDocuments]!) {
      saveClientDocuments(documents: $documents) {
        id
        originalFilename
      }
    }
  """
  describe "mutation :save_client_documents" do
    test "it updates multiple documents", %{conn: conn} do
      client = Factory.insert(:client)
      admin_user = Factory.insert(:user)
      admin_group = Factory.insert(:group, %{slug: "admin", okta_group_slug: "PegaAdmins"})
      Factory.insert(:user_group, %{user_id: admin_user.id, group_id: admin_group.id})

      [doc1, doc2] = Factory.insert_list(2, :document, %{original_filename: "123"})

      Factory.insert(:client_document, %{document_id: doc1.id, client_id: client.id})
      Factory.insert(:client_document, %{document_id: doc2.id, client_id: client.id})

      doc1_updates = %{
        id: doc1.id,
        original_filename: "456"
      }

      doc2_updates = %{
        id: doc2.id,
        original_filename: "456"
      }

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", admin_user.okta_user_uid)
        |> post("/graphql", %{
          query: @save_client_documents,
          variables: %{
            documents: [doc1_updates, doc2_updates]
          }
        })
        |> json_response(200)

      assert %{"data" => %{"saveClientDocuments" => updated_documents}} = response
      assert length(updated_documents) == 2
      assert Map.get(hd(updated_documents), "originalFilename") == "456"
    end

    test "it fails if no document id is passed", %{conn: conn} do
      user = Factory.insert(:user)

      doc_updates = %{
        original_filename: "456"
      }

      %{"errors" => errors} =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @save_client_documents,
          variables: %{
            documents: [doc_updates]
          }
        })
        |> json_response(200)

      assert List.first(errors) |> Map.get("message") ==
               "id is required for each document"
    end

    test "it fails if the document does not exist", %{conn: conn} do
      user = Factory.insert(:user)

      doc_updates = %{
        original_filename: "456",
        id: "1234234234"
      }

      %{"errors" => errors} =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @save_client_documents,
          variables: %{
            documents: [doc_updates]
          }
        })
        |> json_response(200)

      assert List.first(errors) |> Map.get("message") ==
               "document with id #{doc_updates.id} does not exist"
    end

    test "it fails if the user lacks permissions", %{conn: conn} do
      user = Factory.insert(:user)
      client = Factory.insert(:client)
      doc = Factory.insert(:document, %{original_filename: "123"})
      Factory.insert(:client_document, %{document_id: doc.id, client_id: client.id})

      doc_updates = %{
        original_filename: "456",
        id: doc.id
      }

      %{"errors" => errors} =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @save_client_documents,
          variables: %{
            documents: [doc_updates]
          }
        })
        |> json_response(200)

      assert List.first(errors) |> Map.get("message") ==
               "User #{user.id} is not authorized to update document #{doc.id}"
    end
  end

  @delete_user_document """
    mutation deleteUserDocument($id: ID!) {
      deleteUserDocument(id: $id) {
        id
      }
    }
  """

  describe "query :delete_user_document" do
    test "it deletes a document", %{conn: conn} do
      user = Factory.insert(:user)
      country = Factory.insert(:country)
      template = Factory.insert(:document_template, %{country_id: country.id})
      document = Factory.insert(:document, %{document_template_id: template.id})
      Factory.insert(:user_document, %{document_id: document.id, user_id: user.id})

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @delete_user_document,
          variables: %{
            id: document.id
          }
        })
        |> json_response(200)

      assert String.to_integer(response["data"]["deleteUserDocument"]["id"]) == document.id
    end

    test "it does not delete a document if the user doesn't have the correct permissions", %{
      conn: conn
    } do
      user = Factory.insert(:user)
      user2 = Factory.insert(:user)
      country = Factory.insert(:country)
      template = Factory.insert(:document_template, %{country_id: country.id})
      document = Factory.insert(:document, %{document_template_id: template.id})
      Factory.insert(:user_document, %{document_id: document.id, user_id: user.id})

      %{"errors" => errors} =
        conn
        |> put_req_header("test-only-okta-user-uid", user2.okta_user_uid)
        |> post("/graphql", %{
          query: @delete_user_document,
          variables: %{
            id: document.id
          }
        })
        |> json_response(200)

      assert List.first(errors) |> Map.get("message") ==
               "User #{user2.id} is not authorized to delete document #{document.id}"
    end
  end

  @delete_client_document """
    mutation deleteClientDocument($id: ID!) {
      deleteClientDocument(id: $id) {
        id
      }
    }
  """

  describe "query :delete_client_document" do
    test "it deletes a document", %{conn: conn} do
      admin_user = Factory.insert(:user)
      admin_group = Factory.insert(:group, %{slug: "admin", okta_group_slug: "PegaAdmins"})
      Factory.insert(:user_group, %{user_id: admin_user.id, group_id: admin_group.id})

      client = Factory.insert(:client)
      country = Factory.insert(:country)
      template = Factory.insert(:document_template, %{country_id: country.id})
      document = Factory.insert(:document, %{document_template_id: template.id})
      Factory.insert(:client_document, %{document_id: document.id, client_id: client.id})

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", admin_user.okta_user_uid)
        |> post("/graphql", %{
          query: @delete_client_document,
          variables: %{
            id: document.id
          }
        })
        |> json_response(200)

      assert String.to_integer(response["data"]["deleteClientDocument"]["id"]) == document.id
    end

    test "it does not delete a document if the user doesn't have the correct permissions", %{
      conn: conn
    } do
      user = Factory.insert(:user)
      client = Factory.insert(:client)
      country = Factory.insert(:country)
      template = Factory.insert(:document_template, %{country_id: country.id})
      document = Factory.insert(:document, %{document_template_id: template.id})
      Factory.insert(:client_document, %{document_id: document.id, client_id: client.id})

      %{"errors" => errors} =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @delete_client_document,
          variables: %{
            id: document.id
          }
        })
        |> json_response(200)

      assert List.first(errors) |> Map.get("message") ==
               "User #{user.id} is not authorized to delete document #{document.id}"
    end
  end

  @docusign_query """
    query DocusignSigningUrl($documentId: ID!, $redirectUri: String!) {
      docusignSigningUrl(
        documentId: $documentId,
        redirectUri: $redirectUri
      )
    }
  """
  describe "query :docusign_embed_url" do
    test "it errors if the user isn't assigned to the doc", %{conn: conn} do
      user = Factory.insert(:user)
      country = Factory.insert(:country)
      template = Factory.insert(:document_template, %{country: country})
      document = Factory.insert(:document, %{document_template: template})

      %{"errors" => errors} =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @docusign_query,
          variables: %{
            documentId: document.id,
            redirectUri: "foo.bar"
          }
        })
        |> json_response(200)

      assert List.first(errors) |> Map.get("message") ==
               "No user assigned to document_id #{document.id}"
    end

    test "it errors if the doc has no docusign template", %{conn: conn} do
      user = Factory.insert(:user)
      country = Factory.insert(:country)
      template = Factory.insert(:document_template, %{country_id: country.id})
      document = Factory.insert(:document, %{document_template_id: template.id})
      Factory.insert(:user_document, %{document_id: document.id, user_id: user.id})

      %{"errors" => errors} =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @docusign_query,
          variables: %{
            documentId: document.id,
            redirectUri: "foo.bar"
          }
        })
        |> json_response(200)

      assert List.first(errors) |> Map.get("message") ==
               "No docusign template set for document_id #{document.id}"
    end
  end

  @documents_for_client_query """
    query ClientDocuments($clientId: ID!) {
      clientDocuments(clientId: $clientId) {
        id
        documentTemplate {
          exampleFileMimeType
          action
        }
        country {
          name
        }
        status
        url
      }
    }
  """

  describe "query :documents_for_client" do
    test "it returns all documents for a client", %{conn: conn} do
      admin_user = Factory.insert(:user)
      admin_group = Factory.insert(:group, %{slug: "admin", okta_group_slug: "PegaAdmins"})
      Factory.insert(:user_group, %{user_id: admin_user.id, group_id: admin_group.id})

      client = Factory.insert(:client)
      country = Factory.insert(:country)
      template = Factory.insert(:document_template, %{country_id: country.id})
      document = Factory.insert(:document, %{document_template_id: template.id})
      Factory.insert(:client_document, %{document_id: document.id, client_id: client.id})
      Factory.insert_list(2, :document, %{document_template_id: template.id})

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", admin_user.okta_user_uid)
        |> post("/graphql", %{
          query: @documents_for_client_query,
          variables: %{
            clientId: client.id
          }
        })
        |> json_response(200)

      assert Enum.count(response["data"]["clientDocuments"]) == 1
    end
  end

  @save_client_document_query """
    mutation SaveClientDocument(
      $documentId: ID!
      $s3Key: ID
      $originalFilename: String
      $originalMimeType: String
      $status: String
      $fileType: String
      $docusignTemplateId: String
    ) {
      saveClientDocument(
        documentId: $documentId
        s3Key: $s3Key
        originalFilename: $originalFilename
        originalMimeType: $originalMimeType
        status: $status
        fileType: $fileType
        docusignTemplateId: $docusignTemplateId
      ) {
        id
        documentTemplate {
          exampleFileMimeType
          action
        }
        country {
          name
        }
        status
        url
      }
    }
  """

  describe "mutation :save_client_document" do
    test "it returns all documents for a client", %{conn: conn} do
      admin_user = Factory.insert(:user)
      admin_group = Factory.insert(:group, %{slug: "admin", okta_group_slug: "PegaAdmins"})
      Factory.insert(:user_group, %{user_id: admin_user.id, group_id: admin_group.id})

      client = Factory.insert(:client)
      country = Factory.insert(:country)
      template = Factory.insert(:document_template, %{country_id: country.id})

      document =
        Factory.insert(:document, %{
          document_template_id: template.id,
          s3_key: "12345123",
          original_filename: "testdoc.jpg",
          original_mime_type: "image/jpeg",
          status: "not_started"
        })

      Factory.insert(:client_document, %{document_id: document.id, client_id: client.id})
      Factory.insert_list(2, :document, %{document_template_id: template.id})

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", admin_user.okta_user_uid)
        |> post("/graphql", %{
          query: @save_client_document_query,
          variables: %{
            documentId: document.id,
            status: "completed"
          }
        })
        |> json_response(200)

      updated_doc = Repo.get(Document, response["data"]["saveClientDocument"]["id"])
      assert updated_doc.status == "completed"
    end
  end

  @delete_client_s3_metadata """
    mutation DeleteClientS3Metadata($id: ID!, $status: String!) {
      deleteClientS3Metadata(id: $id, status: $status) {
        id
        status
      }
    }
  """

  describe "mutation :delete_client_s3_metadata" do
    test "it deletes a specific document's s3 upload", %{conn: conn} do
      admin_user = Factory.insert(:user)
      admin_group = Factory.insert(:group, %{slug: "admin", okta_group_slug: "PegaAdmins"})
      Factory.insert(:user_group, %{user_id: admin_user.id, group_id: admin_group.id})

      client = Factory.insert(:client)
      country = Factory.insert(:country)
      template = Factory.insert(:document_template, %{country_id: country.id})

      document =
        Factory.insert(:document, %{
          document_template_id: template.id,
          s3_key: "12345123",
          original_filename: "testdoc.jpg",
          original_mime_type: "image/jpeg",
          status: "completed"
        })

      Factory.insert(:client_document, %{document_id: document.id, client_id: client.id})

      status = "not_started"

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", admin_user.okta_user_uid)
        |> post("/graphql", %{
          query: @delete_client_s3_metadata,
          variables: %{
            id: document.id,
            status: status
          }
        })
        |> json_response(200)

      updated_doc = Repo.get(Document, response["data"]["deleteClientS3Metadata"]["id"])
      assert updated_doc.status == status
      assert updated_doc.original_filename == nil
    end
  end

  @user_document_template_categories """
    query DocumentTemplateCategoriesByType($entityType: String!){
      documentTemplateCategoriesByType(entityType: $entityType) {
        id
        slug
      }
    }
  """

  describe "query :document_template_categories_by_type" do
    test "it gets all categories with the passed in entityType", %{conn: conn} do
      Factory.insert_list(4, :document_template_category, %{entity_type: "employee"})
      Factory.insert_list(4, :document_template_category, %{entity_type: "client"})

      %{"data" => %{"documentTemplateCategoriesByType" => categories}} =
        conn
        |> put_req_header("test-only-okta-user-uid", "fake")
        |> post("/graphql", %{
          query: @user_document_template_categories,
          variables: %{
            entityType: "employee"
          }
        })
        |> json_response(200)

      assert Enum.count(categories) == 4
    end
  end
end
