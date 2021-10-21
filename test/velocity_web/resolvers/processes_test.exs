defmodule VelocityWeb.Resolvers.ProcessesTest do
  use VelocityWeb.ConnCase, async: true

  alias Velocity.Contexts.Processes
  alias Velocity.Repo
  alias Velocity.Schema.Process
  alias Velocity.Schema.TaskAssignment

  import Mox

  @process_query """
    query($id: ID!, $userIds: [Integer]) {
      process(id: $id, userIds: $userIds) {
        id
        stages {
          id
          tasks {
            name
            id
            dependentTasks {
              id
            }
            knowledgeArticles {
              url
            }
            taskAssignments {
              id
              user {
                id
              }
            }
          }
        }
      }
    }
  """

  @processes_query """
    query {
      processes {
        id
      }
    }
  """

  @process_mutation """
    mutation CreateProcess($processTemplateId: Int!, $serviceIds: [Int]!) {
      process(processTemplateId: $processTemplateId, serviceIds: $serviceIds) {
        id
        stages {
          id
          tasks {
            id
          }
        }
      }
    }
  """

  describe "query :process" do
    test "it returns a process with stages, tasks", %{conn: conn} do
      process = Factory.insert(:process)

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", "cool")
        |> post("/graphql", %{
          query: @process_query,
          variables: %{id: process.id}
        })
        |> json_response(200)

      assert %{
               "data" => %{
                 "process" => %{
                   "stages" => [
                     %{"tasks" => [%{"id" => _} | _]} | _
                   ]
                 }
               }
             } = response
    end

    test "it allows for user task assignment filters", %{conn: conn} do
      process = Factory.insert(:process)
      role = Factory.insert(:role)

      task =
        process
        |> Map.get(:stages)
        |> List.first()
        |> Map.get(:tasks)
        |> List.first()

      %{user_id: user_id} = Factory.insert(:task_assignment, %{task: task, role: role})

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", "cool")
        |> post("/graphql", %{
          query: @process_query,
          variables: %{id: process.id, userIds: [user_id]}
        })
        |> json_response(200)

      assert %{
               "data" => %{
                 "process" => %{
                   "stages" => [
                     %{"tasks" => [%{"id" => task_id, "taskAssignments" => task_assignments} | _]}
                     | _
                   ]
                 }
               }
             } = response

      assert Enum.count(task_assignments) == 1
      assert Repo.get_by(TaskAssignment, task_id: task_id, user_id: user_id)
    end

    test "it returns dependent tasks", %{conn: conn} do
      process = Factory.insert(:process)

      tasks =
        process
        |> Map.get(:stages)
        |> Enum.sort_by(& &1.stage_template.order)
        |> List.first()
        |> Map.get(:tasks)
        |> Enum.sort_by(& &1.task_template.order)

      task = List.first(tasks)
      task2 = List.last(tasks)

      Factory.insert(:dependent_task, %{task_id: task.id, dependent_task_id: task2.id})

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", "cool")
        |> post("/graphql", %{
          query: @process_query,
          variables: %{id: process.id}
        })
        |> json_response(200)

      assert %{
               "data" => %{
                 "process" => %{
                   "stages" => [
                     %{
                       "tasks" => tasks
                     }
                     | _
                   ]
                 }
               }
             } = response

      %{"id" => task_id, "dependentTasks" => [dependent_task | _]} =
        Enum.find(tasks, fn task ->
          task["dependentTasks"] != []
        end)

      assert task_id == Integer.to_string(task.id)
      assert dependent_task["id"] == Integer.to_string(task2.id)
    end

    test "it returns knowledge articles and name", %{conn: conn} do
      process = Factory.insert(:process)

      process_template = Factory.insert(:process_template, %{type: "a type"})

      stage_template =
        Factory.insert(:stage_template, %{process_template_id: process_template.id})

      task_template =
        Factory.insert(:task_template, %{
          stage_template_id: stage_template.id,
          knowledge_article_search_terms: ["america"]
        })

      changeset =
        Process.changeset(process, %{
          process_template_id: process_template.id,
          percent_complete: 0,
          status: "no way"
        })

      Repo.update!(changeset)

      Velocity.Clients.MockHelpjuice
      |> expect(:search, 2, fn _term ->
        {:ok,
         %{
           body: %{
             "meta" => %{
               current: 1,
               limit: 25,
               total_pages: 1,
               total_count: 3
             },
             "searches" => [
               %{
                 "id" => 592_739,
                 "url" =>
                   "https://kb.velocityglobal.com/terminations/terminations-and-offboarding-brazil"
               },
               %{
                 "id" => 672_784,
                 "url" => "https://kb.velocityglobal.com/117226-msh-expat/672784-process-faq"
               },
               %{
                 "id" => 590_695,
                 "url" =>
                   "https://kb.velocityglobal.com/98080-independent-contractor-risk/independent-contractor-risk-colombia"
               }
             ]
           }
         }}
      end)

      Processes.add_services(process.id, [task_template.service_id])

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", "cool")
        |> post("/graphql", %{
          query: @process_query,
          variables: %{id: process.id}
        })
        |> json_response(200)

      assert %{
               "data" => %{
                 "process" => %{
                   "stages" => [
                     %{
                       "tasks" => [
                         %{"name" => name, "knowledgeArticles" => [article | _]} | _
                       ]
                     }
                     | _
                   ]
                 }
               }
             } = response

      assert name
      assert article["url"]
    end
  end

  describe "query :processes" do
    test "it returns all processes", %{conn: conn} do
      process_template = Factory.insert(:process_template)
      Factory.insert(:process, %{process_template: process_template})
      Factory.insert(:process, %{process_template: process_template})
      Factory.insert(:process, %{process_template: process_template})

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", "cool")
        |> post("/graphql", %{
          query: @processes_query
        })
        |> json_response(200)

      assert %{
               "data" => %{
                 "processes" => processes
               }
             } = response

      assert Enum.count(processes) == 3
    end
  end

  describe "mutation :process" do
    test "it inserts a process based on the template parameters", %{conn: conn} do
      process_template = Factory.insert(:process_template)

      service_ids =
        process_template.stage_templates
        |> List.first()
        |> Map.get(:task_templates)
        |> Enum.map(& &1.service_id)

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", "cool")
        |> post("/graphql", %{
          query: @process_mutation,
          variables: %{processTemplateId: process_template.id, serviceIds: service_ids}
        })
        |> json_response(200)

      assert %{"data" => %{"process" => %{"stages" => [%{"tasks" => _tasks} | _]}}} = response
    end
  end
end
