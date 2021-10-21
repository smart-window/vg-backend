defmodule VelocityWeb.Schema.ProcessTypes do
  @moduledoc false
  use Absinthe.Schema.Notation

  alias Velocity.Repo
  alias Velocity.Schema.ProcessService
  alias Velocity.Schema.Service
  alias Velocity.Schema.StageTemplate
  alias Velocity.Schema.TaskTemplate

  import Ecto.Query

  @desc "process"
  object :process do
    field :id, :id
    field :name, :string
    field :status, :string
    field :percent_complete, :float

    field :stages, list_of(:stage)

    field(:services, list_of(:service)) do
      resolve(fn process, _args, _info ->
        query =
          from(s in Service,
            join: ps in ProcessService,
            on: ps.service_id == s.id,
            where: ps.process_id == ^process.id,
            order_by: s.name
          )

        services = Repo.all(query)
        {:ok, services}
      end)
    end

    field(:template_services, list_of(:service)) do
      resolve(fn process, _args, _info ->
        query =
          from(s in Service,
            join: tt in TaskTemplate,
            on: tt.service_id == s.id,
            join: st in StageTemplate,
            on: st.id == tt.stage_template_id,
            where: st.process_template_id == ^process.process_template_id,
            order_by: s.name,
            distinct: true
          )

        template_services = Repo.all(query)
        {:ok, template_services}
      end)
    end

    field(:client_onboarding, :client_onboarding) do
      resolve(fn process, _args, _info ->
        client_onboarding = Ecto.assoc(process, :client_onboarding) |> Repo.one()
        {:ok, client_onboarding}
      end)
    end

    field(:employee_onboarding, :employee_onboarding) do
      resolve(fn process, _args, _info ->
        employee_onboarding = Ecto.assoc(process, :employee_onboarding) |> Repo.one()
        {:ok, employee_onboarding}
      end)
    end

    field :users, list_of(:user)
  end

  object :stage do
    field :id, :id
    field :name, :string
    field :percent_complete, :float
    field :tasks, list_of(:task)
  end

  object :process_template do
    field :id, :id
    field :type, :string

    field(:services, list_of(:service)) do
      resolve(fn process_template, _args, _info ->
        query =
          from(s in Service,
            join: tt in TaskTemplate,
            on: tt.service_id == s.id,
            join: st in StageTemplate,
            on: st.id == tt.stage_template_id,
            where: st.process_template_id == ^process_template.id,
            order_by: s.name,
            distinct: true
          )

        services = Repo.all(query)
        {:ok, services}
      end)
    end
  end

  object :task_template do
    field :id, :id
    field :context, :json

    field :roles, list_of(:role) do
      resolve(fn task, _args, _info ->
        task = Repo.preload(task, :roles)
        {:ok, task.roles}
      end)
    end
  end

  object :task do
    field :id, :id

    field(:name, :string)
    field :type, :string
    field :status, :string
    field :stage_id, :id

    field(:stage, :stage) do
      resolve(fn task, _args, _info ->
        stage = Ecto.assoc(task, :stage) |> Repo.one()
        {:ok, stage}
      end)
    end

    field(:process, :process) do
      resolve(fn task, _args, _info ->
        process = Ecto.assoc(task, :process) |> Repo.one()
        {:ok, process}
      end)
    end

    field :completion_type, :string
    field :task_assignments, list_of(:task_assignment)
    field :sent_emails, list_of(:sent_email)

    field(:task_comments, list_of(:task_comment)) do
      resolve(fn task, _args, %{context: %{current_user: current_user}} ->
        deeply_loaded_user = current_user |> Repo.preload(user_groups: [group: :permissions])

        permissions =
          Enum.reduce(deeply_loaded_user.user_groups, [], fn user_group, acc1 ->
            new_items =
              Enum.reduce(user_group.group.group_permissions, [], fn group_permission, acc2 ->
                acc2 ++ [group_permission.permission.slug]
              end)

            acc1 ++ new_items
          end)

        can_view_external_comments =
          Enum.find_value(permissions, fn permission -> permission == "view-external-comments" end)

        can_view_internal_comments =
          Enum.find_value(permissions, fn permission -> permission == "view-internal-comments" end)

        comments =
          task.task_comments
          |> Enum.filter(fn task_comment ->
            case task_comment.visibility_type do
              :internal_only -> can_view_internal_comments == true
              :public -> can_view_internal_comments == true || can_view_external_comments == true
            end
          end)

        {:ok, comments}
      end)
    end

    field :dependent_tasks, list_of(:task)
    field :context, :json
    field :knowledge_articles, list_of(:knowledge_article)

    field(:task_template, :task_template) do
      resolve(fn task, _args, _info ->
        task_template = Ecto.assoc(task, :task_template) |> Repo.one()
        {:ok, task_template}
      end)
    end
  end

  object :service do
    field :id, :id
    field :name, :string
  end

  object :task_assignment do
    field :id, :id
    field :user, :user
    field :role, :role
  end

  object :task_comment do
    field :id, :id
    field :user, :user
    field :comment, :string
    field :visibility_type, :string
    field :inserted_at, :string
  end

  object :knowledge_article do
    field :url, :string
  end

  object :process_role_user do
    field :id, :id
    field :process_id, :id
    field :role_id, :id
    field :user_id, :id
  end
end
