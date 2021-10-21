defmodule VelocityWeb.Resolvers.MeetingsTest do
  use VelocityWeb.ConnCase, async: true

  alias Velocity.Repo

  @upsert_client_meeting """
    mutation UpsertClientMeeting($id: ID, $client_id: ID, $description: String, $meeting_date: Date, $notes: String) {
      upsert_client_meeting(id: $id, client_id: $client_id, description: $description, meeting_date: $meeting_date, notes: $notes) {
        id
        meeting {
          description
        }
      }
    }
  """

  @delete_client_meeting """
    mutation DeleteClientMeeting($id: ID!) {
      delete_client_meeting(id: $id) {
        id
      }
    }
  """

  describe "mutate :meeting" do
    test "it upserts a client meeting record", %{conn: conn} do
      user = Factory.insert(:user)
      meeting = Factory.insert(:meeting)
      client = Factory.insert(:client)
      client_meeting = Factory.insert(:client_meeting, %{client: client, meeting: meeting})

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @upsert_client_meeting,
          variables: %{
            client_id: client.id,
            description: Faker.Lorem.sentence(5),
            meeting_date: "2021-05-17",
            notes: Faker.Lorem.sentence(10)
          }
        })
        |> json_response(200)

      assert %{
               "data" => %{
                 "upsert_client_meeting" => %{
                   "id" => client_meeting_id1,
                   "meeting" => %{"description" => _description}
                 }
               }
             } = response

      assert String.to_integer(client_meeting_id1) != client_meeting.id

      new_description = Faker.Lorem.sentence(5)

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @upsert_client_meeting,
          variables: %{
            id: client_meeting_id1,
            description: new_description
          }
        })
        |> json_response(200)

      assert %{
               "data" => %{
                 "upsert_client_meeting" => %{
                   "id" => client_meeting_id2,
                   "meeting" => %{"description" => client_meeting_description}
                 }
               }
             } = response

      assert client_meeting_id2 == client_meeting_id1
      assert new_description == client_meeting_description
    end

    test "it deletes a client meeting record", %{conn: conn} do
      user = Factory.insert(:user)
      meeting = Factory.insert(:meeting)
      client = Factory.insert(:client)
      client_meeting = Factory.insert(:client_meeting, %{client: client, meeting: meeting})

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @delete_client_meeting,
          variables: %{
            id: client_meeting.id
          }
        })
        |> json_response(200)

      assert %{
               "data" => %{"delete_client_meeting" => %{"id" => deleted_client_meeting_id}}
             } = response

      assert String.to_integer(deleted_client_meeting_id) == client_meeting.id
    end
  end
end
