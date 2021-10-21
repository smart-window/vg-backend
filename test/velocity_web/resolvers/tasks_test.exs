defmodule VelocityWeb.Resolvers.TasksTest do
  use VelocityWeb.ConnCase, async: true

  @task_query """
    query($id: ID!) {
      task(id: $id) {
        id
        taskAssignments {
          user {
            id
          }
        }
      }
    }
  """

  @task_assignment_mutation """
    mutation TaskAssignment($userId: Integer!, $taskId: Integer!, $roleId: Integer!) {
      taskAssignment(userId: $userId, taskId: $taskId, roleId: $roleId) {
        id
        taskAssignments {
          id
          user {
            id
          }
        }
      }
    }
  """

  @update_task_status_mutation """
    mutation UpdateTaskStatus($taskId: Integer!, $status: String!) {
      updateTaskStatus(taskId: $taskId, status: $status) {
        id
        status
      }
    }
  """

  @add_task_comment_mutation """
    mutation AddTaskComment($taskId: Integer!, $comment: String!, $visibilityType: String!) {
      addTaskComment(taskId: $taskId, comment: $comment, visibilityType: $visibilityType) {
        taskComments {
          id
          comment
          visibilityType
        }
      }
    }
  """

  @delete_task_comment_mutation """
    mutation DeleteTaskComment($id: Integer!) {
      deleteTaskComment(id: $id) {
        id
      }
    }
  """
  describe "query :task" do
    test "it returns a task with assignments", %{conn: conn} do
      process = Factory.insert(:process)
      user = Factory.insert(:user)
      role = Factory.insert(:role)

      task =
        process.stages
        |> List.first()
        |> Map.get(:tasks)
        |> List.first()

      Factory.insert(:task_assignment, %{task: task, user: user, role: role})

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", "cool")
        |> post("/graphql", %{
          query: @task_query,
          variables: %{id: task.id}
        })
        |> json_response(200)

      assert %{
               "data" => %{
                 "task" => %{"taskAssignments" => [%{"user" => %{"id" => user_id}} | _]}
               }
             } = response

      assert user.id == String.to_integer(user_id)
    end
  end

  describe "mutation :task_assignment" do
    test "it inserts a task assignment", %{conn: conn} do
      process = Factory.insert(:process)
      user = Factory.insert(:user)
      role = Factory.insert(:role)

      task_id =
        process.stages
        |> List.first()
        |> Map.get(:tasks)
        |> List.first()
        |> Map.get(:id)

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", "cool")
        |> post("/graphql", %{
          query: @task_assignment_mutation,
          variables: %{userId: user.id, taskId: task_id, roleId: role.id}
        })
        |> json_response(200)

      assert %{
               "data" => %{
                 "taskAssignment" => %{"taskAssignments" => [%{"user" => %{"id" => user_id}} | _]}
               }
             } = response

      assert user.id == String.to_integer(user_id)
    end
  end

  describe "mutation :update_task_status" do
    test "it updates the completed attribute", %{conn: conn} do
      process = Factory.insert(:process)

      task_id =
        process.stages
        |> List.first()
        |> Map.get(:tasks)
        |> List.first()
        |> Map.get(:id)

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", "cool")
        |> post("/graphql", %{
          query: @update_task_status_mutation,
          variables: %{taskId: Integer.to_string(task_id), status: "in_progress"}
        })
        |> json_response(200)

      assert %{
               "data" => %{
                 "updateTaskStatus" => %{"status" => status}
               }
             } = response

      assert status == "in_progress"
    end
  end

  def setup_user do
    user = Factory.insert(:user)
    group = Factory.insert(:group, %{slug: "csr", okta_group_slug: "CSR"})
    permission = Factory.insert(:permission, %{slug: "view-external-comments"})
    Factory.insert(:group_permission, group_id: group.id, permission_id: permission.id)
    Factory.insert(:user_group, %{user_id: user.id, group_id: group.id})
    user
  end

  describe "mutation :add_task_comment" do
    test "it adds a task comment", %{conn: conn} do
      user = setup_user()

      process = Factory.insert(:process)

      task_id =
        process.stages
        |> List.first()
        |> Map.get(:tasks)
        |> List.first()
        |> Map.get(:id)

      conn
      |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
      |> post("/graphql", %{
        query: @add_task_comment_mutation,
        variables: %{taskId: task_id, comment: "Public test comment", visibilityType: "public"}
      })
      |> json_response(200)

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @add_task_comment_mutation,
          variables: %{
            taskId: task_id,
            comment: "Internal test comment",
            visibilityType: "internalOnly"
          }
        })
        |> json_response(200)

      assert %{
               "data" => %{
                 "addTaskComment" => %{
                   "taskComments" => [
                     %{
                       "id" => _,
                       "comment" => public_comment,
                       "visibilityType" => visibility_type
                     }
                   ]
                 }
               }
             } = response

      assert public_comment == "Public test comment"
      assert visibility_type == "public"
    end

    test "it deletes a task comment", %{conn: conn} do
      user = setup_user()

      process = Factory.insert(:process)

      task_id =
        process.stages
        |> List.first()
        |> Map.get(:tasks)
        |> List.first()
        |> Map.get(:id)

      conn
      |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
      |> post("/graphql", %{
        query: @add_task_comment_mutation,
        variables: %{taskId: task_id, comment: "Public test comment", visibilityType: "public"}
      })
      |> json_response(200)

      response1 =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @add_task_comment_mutation,
          variables: %{
            taskId: task_id,
            comment: "Internal test comment",
            visibilityType: "internalOnly"
          }
        })
        |> json_response(200)

      assert %{
               "data" => %{
                 "addTaskComment" => %{
                   "taskComments" => [
                     %{
                       "id" => public_comment_id,
                       "comment" => _,
                       "visibilityType" => _
                     }
                   ]
                 }
               }
             } = response1

      response2 =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @delete_task_comment_mutation,
          variables: %{id: public_comment_id}
        })
        |> json_response(200)

      assert %{
               "data" => %{
                 "deleteTaskComment" => %{
                   "id" => deleted_comment_id
                 }
               }
             } = response2

      assert public_comment_id == deleted_comment_id
    end
  end
end
