defmodule VelocityWeb.Resolvers.SentEmailsTest do
  use VelocityWeb.ConnCase, async: true

  @upsert_client_sent_email """
    mutation UpsertClientSentEmail($id: ID, $client_id: ID, $description: String, $sent_date: NaiveDateTime, $subject: String, $body: String) {
      upsert_client_sent_email(id: $id, client_id: $client_id, description: $description, sent_date: $sent_date, subject: $subject, body: $body) {
        id
        sent_email {
          description
        }
      }
    }
  """

  @delete_client_sent_email """
    mutation DeleteClientSentEmail($id: ID!) {
      delete_client_sent_email(id: $id) {
        id
      }
    }
  """

  describe "mutate :sent_email" do
    test "it upserts a client sent email", %{conn: conn} do
      user = Factory.insert(:user)
      sent_email = Factory.insert(:sent_email)
      client = Factory.insert(:client)

      client_sent_email =
        Factory.insert(:client_sent_email, %{client: client, sent_email: sent_email})

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @upsert_client_sent_email,
          variables: %{
            client_id: client.id,
            description: Faker.Lorem.sentence(5),
            sent_date: "2021-05-17T00:00:00",
            subject: Faker.Lorem.sentence(10),
            body: Faker.Lorem.sentence(10)
          }
        })
        |> json_response(200)

      assert %{
               "data" => %{
                 "upsert_client_sent_email" => %{
                   "id" => client_sent_email_id1,
                   "sent_email" => %{"description" => _description}
                 }
               }
             } = response

      assert String.to_integer(client_sent_email_id1) != client_sent_email.id

      new_description = Faker.Lorem.sentence(5)

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @upsert_client_sent_email,
          variables: %{
            id: client_sent_email_id1,
            description: new_description
          }
        })
        |> json_response(200)

      assert %{
               "data" => %{
                 "upsert_client_sent_email" => %{
                   "id" => client_sent_email_id2,
                   "sent_email" => %{"description" => client_sent_email_description}
                 }
               }
             } = response

      assert client_sent_email_id2 == client_sent_email_id1
      assert new_description == client_sent_email_description
    end

    test "it deletes a client sent email", %{conn: conn} do
      user = Factory.insert(:user)
      sent_email = Factory.insert(:sent_email)
      client = Factory.insert(:client)

      client_sent_email =
        Factory.insert(:client_sent_email, %{client: client, sent_email: sent_email})

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @delete_client_sent_email,
          variables: %{
            id: client_sent_email.id
          }
        })
        |> json_response(200)

      assert %{
               "data" => %{"delete_client_sent_email" => %{"id" => deleted_client_sent_email_id}}
             } = response

      assert String.to_integer(deleted_client_sent_email_id) == client_sent_email.id
    end
  end
end
