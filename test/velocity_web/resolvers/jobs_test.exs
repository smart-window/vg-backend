defmodule VelocityWeb.Resolvers.JobsTest do
  use VelocityWeb.ConnCase, async: true

  alias Velocity.Repo
  alias Velocity.Schema.Job

  @get_job_query """
    query($id: ID!) {
      job(id: $id) {
        id
        title
        client {
          id
        }
      }
    }
  """

  @create_job_mutation """
    mutation CreateJob($client_id: ID!, $title: String!) {
      createJob(client_id: $client_id, title: $title) {
        id
        title
        client {
          id
        }
      }
    }
  """

  @update_job_mutation """
    mutation UpdateJob($id: ID!, $title: String!) {
      updateJob(id: $id, title: $title) {
        id
        title
        client {
          id
        }
      }
    }
  """

  @delete_job_mutation """
    mutation DeleteJob($id: ID!) {
      deleteJob(id: $id) {
        id
      }
    }
  """

  def setup_user do
    country = Factory.insert(:country)
    address = Factory.insert(:address, %{country_id: country.id})

    Factory.insert(:user, %{
      avatar_url: "http://old.url",
      work_address_id: address.id
    })
  end

  def setup_admin_user do
    country = Factory.insert(:country)
    address = Factory.insert(:address, %{country_id: country.id})

    admin_user = Factory.insert(:user, %{work_address_id: address.id})
    admin_group = Factory.insert(:group, %{slug: "admin", okta_group_slug: "PegaAdmins"})
    Factory.insert(:user_group, %{user_id: admin_user.id, group_id: admin_group.id})

    admin_user
  end

  describe "query :jobs" do
    test "it gets a job if the job is owned by the user", %{conn: conn} do
      user = setup_user()

      employee =
        Factory.insert(:employee, %{
          user: user
        })

      client = Factory.insert(:client)

      job =
        Factory.insert(:job, %{
          client: client,
          title: "My Job"
        })

      Factory.insert(:employment, %{
        job: job,
        employee: employee
      })

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @get_job_query,
          variables: %{
            id: job.id
          }
        })
        |> json_response(200)

      assert %{
               "data" => %{
                 "job" => %{
                   "id" => job_id,
                   "title" => "My Job",
                   "client" => %{
                     "id" => client_id
                   }
                 }
               }
             } = response

      assert String.to_integer(job_id) == job.id
      assert String.to_integer(client_id) == client.id
    end
  end

  describe "mutation :jobs" do
    test "it creates a job", %{conn: conn} do
      user = setup_admin_user()

      client = Factory.insert(:client)

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @create_job_mutation,
          variables: %{
            client_id: client.id,
            title: "My Job"
          }
        })
        |> json_response(200)

      assert %{
               "data" => %{
                 "createJob" => %{
                   "id" => job_id,
                   "title" => "My Job",
                   "client" => %{
                     "id" => client_id
                   }
                 }
               }
             } = response

      assert String.to_integer(client_id) == client.id
      assert Repo.get(Job, job_id)
    end

    test "it updates an existing job when the user is an admin", %{conn: conn} do
      user = setup_admin_user()
      job_user = setup_user()

      employee =
        Factory.insert(:employee, %{
          user: job_user
        })

      client = Factory.insert(:client)

      job =
        Factory.insert(:job, %{
          client: client,
          title: "My Job"
        })

      Factory.insert(:employment, %{
        job: job,
        employee: employee
      })

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @update_job_mutation,
          variables: %{
            id: job.id,
            title: "My Updated Job"
          }
        })
        |> json_response(200)

      assert %{
               "data" => %{
                 "updateJob" => %{
                   "id" => job_id,
                   "title" => "My Updated Job",
                   "client" => %{
                     "id" => client_id
                   }
                 }
               }
             } = response

      assert String.to_integer(job_id) == job.id
      assert String.to_integer(client_id) == client.id
    end

    test "it returns an error on a job update when the user is not an admin", %{conn: conn} do
      user = setup_user()

      client = Factory.insert(:client)

      job =
        Factory.insert(:job, %{
          client: client,
          title: "My Job"
        })

      %{"errors" => errors} =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @update_job_mutation,
          variables: %{
            id: job.id,
            title: "My Updated Job"
          }
        })
        |> json_response(200)

      assert List.first(errors) |> Map.get("message") ==
               "User #{user.id} is not authorized to edit job #{job.id}"
    end

    test "it deletes an existing job", %{conn: conn} do
      user = setup_admin_user()

      client = Factory.insert(:client)

      job =
        Factory.insert(:job, %{
          client: client,
          title: "My Job"
        })

      assert Repo.get(Job, job.id)

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @delete_job_mutation,
          variables: %{
            id: job.id
          }
        })
        |> json_response(200)

      assert %{"data" => %{"deleteJob" => %{"id" => job_id}}} = response
      assert String.to_integer(job_id) == job.id
      assert Repo.get(Job, job.id) == nil
    end
  end
end
