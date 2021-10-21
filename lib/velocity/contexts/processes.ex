defmodule Velocity.Contexts.Processes do
  alias Ecto.Multi
  alias Velocity.Contexts.AutoTasks
  alias Velocity.Event
  alias Velocity.Repo
  alias Velocity.Schema.DependentTask
  alias Velocity.Schema.Process
  alias Velocity.Schema.ProcessRoleUser
  alias Velocity.Schema.ProcessService
  alias Velocity.Schema.ProcessTemplate
  alias Velocity.Schema.Service
  alias Velocity.Schema.Stage
  alias Velocity.Schema.Task
  alias Velocity.Schema.TaskAssignment
  alias Velocity.Schema.TaskTemplateRoleNotification
  alias Velocity.Schema.User
  alias Velocity.Schema.UserRole

  import Ecto.Query

  require Logger

  def all do
    {:ok, Repo.all(Process)}
  end

  def create_for_template_name(process_template_name, service_names)
      when is_list(service_names) do
    process_template = Repo.get_by(ProcessTemplate, type: process_template_name)

    service_ids =
      Enum.map(service_names, fn name ->
        service = Repo.get_by(Service, name: name)
        service.id
      end)

    create(process_template.id, service_ids)
  end

  # credo:disable-for-lines:109 Credo.Check.Refactor.Nesting
  def create(process_template_id, service_ids) when is_list(service_ids) do
    query =
      from(pt in ProcessTemplate,
        join: ts in assoc(pt, :stage_templates),
        join: tt in assoc(ts, :task_templates),
        where: pt.id == ^process_template_id and tt.service_id in ^service_ids,
        preload: [stage_templates: {ts, task_templates: {tt, :dependent_task_templates}}]
      )

    template_with_matching_tasks = Repo.one(query)
    inserted_and_updated_at = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    {:ok, %{process: %{id: id}}} =
      Multi.new()
      |> Multi.insert(
        :process,
        Process.build(%{
          process_template_id: template_with_matching_tasks.id,
          percent_complete: 0.0,
          status: "not_started"
        })
      )
      |> Multi.insert_all(:process_services, ProcessService, fn %{process: process} ->
        Enum.map(service_ids, fn service_id ->
          %{
            process_id: process.id,
            service_id: service_id,
            inserted_at: inserted_and_updated_at,
            updated_at: inserted_and_updated_at
          }
        end)
      end)
      |> Multi.insert_all(
        :stages,
        Stage,
        fn %{process: process} ->
          Enum.map(template_with_matching_tasks.stage_templates, fn stage_template ->
            %{
              name: stage_template.name,
              process_id: process.id,
              stage_template_id: stage_template.id,
              percent_complete: 0.0,
              inserted_at: inserted_and_updated_at,
              updated_at: inserted_and_updated_at
            }
          end)
        end,
        returning: true
      )
      |> Multi.insert_all(
        :tasks,
        Task,
        fn %{
             stages: {_, stages}
           } ->
          Enum.map(stages, fn stage ->
            stage_template =
              Enum.find(
                template_with_matching_tasks.stage_templates,
                &(&1.id == stage.stage_template_id)
              )

            Enum.map(stage_template.task_templates, fn task_template ->
              %{
                stage_id: stage.id,
                process_id: stage.process_id,
                task_template_id: task_template.id,
                order: task_template.order,
                type: task_template.type,
                service_id: task_template.service_id,
                inserted_at: inserted_and_updated_at,
                updated_at: inserted_and_updated_at,
                completion_type: task_template.completion_type
              }
            end)
          end)
          |> List.flatten()
        end,
        returning: true
      )
      |> Multi.insert_all(:task_dependencies, DependentTask, fn %{
                                                                  tasks: {_, tasks}
                                                                } ->
        tasks =
          Enum.map(tasks, fn task ->
            Repo.preload(task, task_template: :dependent_task_templates)
          end)

        Enum.map(tasks, fn task ->
          Enum.map(task.task_template.dependent_task_templates, fn dependent_task_template ->
            dependent_task =
              Enum.find(
                tasks,
                &(&1.task_template.id == dependent_task_template.id)
              )

            %{
              task_id: task.id,
              dependent_task_id: dependent_task.id,
              inserted_at: inserted_and_updated_at,
              updated_at: inserted_and_updated_at
            }
          end)
        end)
        |> List.flatten()
      end)
      |> Repo.transaction()

    process = get_by(id: id)

    {:ok, process}
  end

  def add_services(process_id, service_ids) do
    process = get_by(id: process_id)
    current_service_ids = Enum.map(process.process_services, & &1.service_id)
    service_ids_to_add = service_ids -- current_service_ids

    template_with_matching_tasks =
      get_process_template(process.process_template_id, service_ids_to_add)

    inserted_and_updated_at = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    process_services_args =
      Enum.map(service_ids_to_add, fn service_id ->
        %{
          process_id: process.id,
          service_id: service_id,
          inserted_at: inserted_and_updated_at,
          updated_at: inserted_and_updated_at
        }
      end)

    stage_args =
      Enum.map(template_with_matching_tasks.stage_templates, fn stage_template ->
        %{
          name: stage_template.name,
          process_id: process.id,
          stage_template_id: stage_template.id,
          percent_complete: 0.0,
          inserted_at: inserted_and_updated_at,
          updated_at: inserted_and_updated_at
        }
      end)

    {:ok, _} =
      Multi.new()
      |> Multi.insert_all(:process_services, ProcessService, process_services_args)
      |> Multi.insert_all(:stages, Stage, stage_args,
        on_conflict: [set: [updated_at: inserted_and_updated_at]],
        conflict_target: [:process_id, :stage_template_id],
        returning: true
      )
      |> Multi.insert_all(:tasks, Task, fn %{
                                             stages: {_, stages}
                                           } ->
        Enum.map(stages, fn stage ->
          stage_template =
            Enum.find(
              template_with_matching_tasks.stage_templates,
              &(&1.id == stage.stage_template_id)
            )

          # credo:disable-for-lines:7 Credo.Check.Refactor.Nesting
          Enum.map(stage_template.task_templates, fn task_template ->
            %{
              task_template_id: task_template.id,
              stage_id: stage.id,
              process_id: stage.process_id,
              service_id: task_template.service_id,
              inserted_at: inserted_and_updated_at,
              updated_at: inserted_and_updated_at,
              completion_type: task_template.completion_type
            }
          end)
        end)
        |> List.flatten()
      end)
      |> Repo.transaction()

    {:ok, filter(process_id)}
  end

  def remove_services(process_id, service_ids) do
    process = get_by(id: process_id)
    current_service_ids = Enum.map(process.process_services, & &1.service_id)
    service_ids_to_remove = Enum.filter(current_service_ids, &(&1 in service_ids))

    process_services_to_delete_query =
      from(ps in ProcessService,
        where: ps.process_id == ^process.id and ps.service_id in ^service_ids_to_remove
      )

    task_ids =
      Repo.all(
        from(t in Task,
          where: t.process_id == ^process.id and t.service_id in ^service_ids_to_remove,
          select: t.id
        )
      )

    task_assignments_to_delete_query = from(ta in TaskAssignment, where: ta.task_id in ^task_ids)

    tasks_to_delete_query = from(t in Task, where: t.id in ^task_ids)

    {:ok, _} =
      Multi.new()
      |> Multi.delete_all(:process_services, process_services_to_delete_query)
      |> Multi.delete_all(:task_assignments, task_assignments_to_delete_query)
      |> Multi.delete_all(:tasks, tasks_to_delete_query)
      |> Multi.delete_all(:stages, fn _ ->
        stages_to_delete_query =
          from(s in Stage,
            left_join: t in Task,
            on: s.id == t.stage_id,
            where: fragment("? IS NULL", t.id),
            select: s.id
          )

        stage_ids = Repo.all(stages_to_delete_query)
        from(s in Stage, where: s.id in ^stage_ids)
      end)
      |> Repo.transaction()

    {:ok, filter(process_id)}
  end

  def filter(process_id, filters \\ %{}) do
    from(p in Process,
      as: :process,
      join: s in assoc(p, :stages),
      as: :stages,
      join: st in assoc(s, :stage_template),
      as: :stage_template,
      join: t in assoc(s, :tasks),
      as: :tasks,
      join: tt in assoc(t, :task_template),
      as: :task_template,
      left_join: se in assoc(t, :sent_emails),
      as: :sent_emails,
      left_join: seu in assoc(se, :sent_email_users),
      as: :sent_email_users,
      left_join: u in assoc(seu, :user),
      as: :sent_email_user,
      left_join: ta in assoc(t, :task_assignments),
      as: :task_assignments,
      left_join: tau in assoc(ta, :user),
      as: :task_assigned_user,
      left_join: tar in assoc(ta, :role),
      as: :task_assigned_role,
      left_join: dt in assoc(t, :dependent_tasks),
      as: :dependent_tasks,
      left_join: u in assoc(ta, :user),
      as: :user
    )
    |> where([process: p], p.id == ^process_id)
    |> where(^filter_where(filters))
    |> preload(
      [
        stages: s,
        tasks: t,
        dependent_tasks: dt,
        task_template: tt,
        sent_emails: se,
        sent_email_users: seu,
        user: u,
        stage_template: st,
        task_assignments: ta,
        task_assigned_user: tau,
        task_assigned_role: tar
      ],
      stages:
        {s,
         tasks:
           {t,
            sent_emails: {se, sent_email_users: {seu, user: u}},
            dependent_tasks: dt,
            task_template: tt,
            task_assignments: {ta, user: tau, role: tar}},
         stage_template: st}
    )
    |> order_by([stage_template: st, task_template: tt], asc: st.order, asc: tt.order)
    |> Repo.one()
    |> (fn
          nil ->
            nil

          process ->
            all_tasks =
              Enum.reduce(process.stages, [], fn stage, acc ->
                acc ++ stage.tasks
              end)

            stages =
              Enum.map(process.stages, fn stage ->
                tasks =
                  Enum.map(stage.tasks, fn task ->
                    dependent_tasks =
                      Enum.map(task.dependent_tasks, fn dependent_task ->
                        found_dependent_task =
                          Enum.find(all_tasks, fn t ->
                            t.id == dependent_task.id
                          end)

                        dependent_task
                        |> Map.put(:name, found_dependent_task.task_template.name)
                      end)

                    task
                    |> Map.put(:name, task.task_template.name)
                    |> Map.put(:dependent_tasks, dependent_tasks)
                    |> Map.put(:context, task.task_template.context)
                    |> Map.put(:knowledge_articles, build_knowledge_articles(task.task_template))
                  end)

                Map.put(stage, :tasks, tasks)
              end)

            Map.put(process, :stages, stages)
        end).()
    |> Repo.preload(:services)
  end

  def get_by(keyword) do
    Process
    |> Repo.get_by(keyword)
    |> Repo.preload(stages: :tasks)
    |> Repo.preload(:tasks)
    |> Repo.preload(:services)
  end

  @doc """
    Will set the process status to in_progress (if needed) and then trigger
    any auto tasks that can be run for a process.
  """
  def start(process) do
    process
    |> Process.changeset(%{status: "in_progress"})
    |> Repo.update()

    run_auto_tasks(process)
  end

  @doc """
  this function will loop through the relevant process -> stage -> tasks in order to calculate and update the completion percentage

  call this function *after* updating a task status
  """
  def update_completion_percentage(task) do
    total_process_tasks =
      Repo.aggregate(from(t in Task, where: t.process_id == ^task.process_id), :count)

    process_completed_tasks =
      Repo.aggregate(
        from(t in Task, where: t.process_id == ^task.process_id and t.status == "completed"),
        :count
      )

    process_percent_complete = process_completed_tasks / total_process_tasks

    if process_percent_complete == 1.0 do
      # TODO handle process completed
    end

    Repo.update_all(
      from(p in Process,
        where: p.id == ^task.process_id
      ),
      set: [percent_complete: process_percent_complete]
    )

    total_stage_tasks =
      Repo.aggregate(from(t in Task, where: t.stage_id == ^task.stage_id), :count)

    stage_completed_tasks =
      Repo.aggregate(
        from(t in Task, where: t.stage_id == ^task.stage_id and t.status == "completed"),
        :count
      )

    stage_percent_complete = stage_completed_tasks / total_stage_tasks

    if stage_percent_complete == 1.0 do
      # TODO handle stage completed
    end

    Repo.update_all(
      from(s in Stage,
        where: s.id == ^task.stage_id
      ),
      set: [percent_complete: stage_percent_complete]
    )

    users_assigned_to_task =
      Repo.all(
        from(u in User,
          join: ta in assoc(u, :task_assignments),
          where: ta.task_id == ^task.id
        )
      )

    # NOTE: filter through task assignments and user roles to ensure
    # user is assigned to task and still has the role assigned in
    # process_user_roles (ideally, removing a role will remove all
    # such process_user_roles entries but just to be sure)
    users_to_notify =
      Repo.all(
        from(u in User,
          join: pru in assoc(u, :process_role_users),
          join: p in assoc(pru, :process),
          join: t in assoc(p, :tasks),
          join: ta in TaskAssignment,
          on: ta.task_id == t.id and ta.user_id == pru.user_id,
          join: tt in assoc(t, :task_template),
          join: ttrn in TaskTemplateRoleNotification,
          on: ttrn.task_template_id == tt.id and ttrn.role_id == pru.role_id,
          join: ur in UserRole,
          on: ur.user_id == pru.user_id and ur.role_id == ttrn.role_id,
          where: t.id == ^task.id
        )
      )

    # TODO change async to true once we're sure things are working
    # NOTE: place all users assigned to task in "users_assigned_to_task"
    # actor bucket, place all users to notify in "users_to_notify" actor
    # bucket
    Event.occurred(
      :task_completed,
      %{
        task: task,
        users_assigned_to_task: users_assigned_to_task,
        users_to_notify: users_to_notify
      },
      async: false
    )

    :ok
  end

  @doc """
    Performs any process activities necessary based on a task going complete
  """
  def task_status_changed(task = %Task{status: "completed"}) do
    users_assigned_to_task =
      Repo.all(
        from(u in User,
          join: ta in assoc(u, :task_assignments),
          where: ta.task_id == ^task.id
        )
      )

    # NOTE: filter through task assignments and user roles to ensure
    # user is assigned to task and still has the role assigned in
    # process_user_roles (ideally, removing a role will remove all
    # such process_user_roles entries but just to be sure)
    users_to_notify =
      Repo.all(
        from(u in User,
          join: pru in assoc(u, :process_role_users),
          join: p in assoc(pru, :process),
          join: t in assoc(p, :tasks),
          join: ta in TaskAssignment,
          on: ta.task_id == t.id and ta.user_id == pru.user_id,
          join: tt in assoc(t, :task_template),
          join: ttrn in TaskTemplateRoleNotification,
          on: ttrn.task_template_id == tt.id and ttrn.role_id == pru.role_id,
          join: ur in UserRole,
          on: ur.user_id == pru.user_id and ur.role_id == ttrn.role_id,
          where: t.id == ^task.id
        )
      )

    # TODO change async to true once we're sure things are working
    # NOTE: place all users assigned to task in "users_assigned_to_task"
    # actor bucket, place all users to notify in "users_to_notify" actor
    # bucket
    Event.occurred(
      :task_completed,
      %{
        task: task,
        users_assigned_to_task: users_assigned_to_task,
        users_to_notify: users_to_notify
      },
      async: false
    )

    :ok
  end

  def task_status_changed(_) do
    :ok
  end

  @doc """
    Assignes the specified users and role to the process. A side effect will
    be to ensure the users are assigned to all tasks for which a task template 
    role of the same type is assigned. 
  """
  def add_process_role_users(process_id, role_id, user_ids) do
    tasks_with_role =
      Repo.all(
        from(t in Task,
          join: tt in assoc(t, :task_template),
          join: ttr in assoc(tt, :task_template_roles),
          where: t.process_id == ^process_id and ttr.role_id == ^role_id,
          select: t.id
        )
      )

    Enum.each(user_ids, fn user_id ->
      Repo.insert(
        ProcessRoleUser.changeset(%ProcessRoleUser{}, %{
          process_id: process_id,
          user_id: user_id,
          role_id: role_id
        }),
        on_conflict: :nothing
      )

      tasks_with_role
      |> Enum.each(fn task_id ->
        Repo.insert(
          TaskAssignment.changeset(%TaskAssignment{}, %{
            task_id: task_id,
            user_id: user_id,
            role_id: role_id
          }),
          on_conflict: :nothing
        )
      end)
    end)

    {:ok, filter(process_id)}
  end

  @doc """
    Removes the specified users and role from the process. A side effect will
    be to ensure the users are removed from all tasks for which a task template 
    role of the same type was assigned. 
  """
  def remove_process_role_users(process_id, role_id, user_ids) do
    tasks_with_role =
      Repo.all(
        from(t in Task,
          join: tt in assoc(t, :task_template),
          join: ttr in assoc(tt, :task_template_roles),
          where: t.process_id == ^process_id and ttr.role_id == ^role_id,
          select: t.id
        )
      )

    from(ta in TaskAssignment,
      where: ta.task_id in ^tasks_with_role and ta.user_id in ^user_ids and ta.role_id == ^role_id
    )
    |> Repo.delete_all()

    from(pru in ProcessRoleUser,
      where:
        pru.process_id == ^process_id and pru.role_id == ^role_id and pru.user_id in ^user_ids
    )
    |> Repo.delete_all()

    {:ok, filter(process_id)}
  end

  @doc """
    Runs any tasks with a completion type of "auto" for the process
    that can be run.
  """
  def run_auto_tasks(process) do
    # We will fetch all tasks for the process and attempt to run
    # each as an auto task... the AutoTasks module will handle the
    # details for us (e.g. not running an auto task if it has dependencies
    # while are not yet completed, etc.)
    process =
      if Ecto.assoc_loaded?(process.tasks) do
        process
      else
        Repo.preload(process, :tasks)
      end

    # NOTE: not sure order matters for this step but it can't hurt
    tasks_in_order = Enum.sort(process.tasks, &(&1.order < &2.order))

    Enum.each(tasks_in_order, fn task ->
      AutoTasks.run_auto_task(task)
    end)
  end

  defp filter_where(filters) when is_map(filters) do
    Enum.reduce(filters, dynamic(true), fn
      {:user_ids, value}, dynamic ->
        dynamic([user: u], ^dynamic and u.id in ^value)

      {:task_statuses, value}, dynamic ->
        dynamic([tasks: t], ^dynamic and t.status in ^value)

      {_, _}, dynamic ->
        dynamic
    end)
  end

  defp get_process_template(process_template_id, service_ids) do
    query =
      from(pt in ProcessTemplate,
        join: ts in assoc(pt, :stage_templates),
        join: tt in assoc(ts, :task_templates),
        where: pt.id == ^process_template_id and tt.service_id in ^service_ids,
        preload: [stage_templates: {ts, task_templates: tt}]
      )

    Repo.one(query)
  end

  defp build_knowledge_articles(task_template) do
    search_term_knowledge_articles =
      if task_template.knowledge_article_search_terms &&
           task_template.knowledge_article_search_terms != [] do
        task_template.knowledge_article_search_terms
        |> Enum.map(fn term ->
          case helpjuice_client().search(term) do
            {:ok, %{body: %{"searches" => searches}}} ->
              Enum.map(
                searches,
                &%{
                  url: &1["url"]
                }
              )

            error ->
              Logger.error("helpjuice request error: #{inspect(error)}")
              []
          end
        end)
        |> List.flatten()
      else
        []
      end

    url_knowledge_articles =
      if task_template.knowledge_article_urls && task_template.knowledge_article_urls != [] do
        Enum.map(task_template.knowledge_article_urls, &%{url: &1})
      else
        []
      end

    url_knowledge_articles ++ search_term_knowledge_articles
  end

  defp helpjuice_client,
    do: Application.get_env(:velocity, :helpjuice_client, Velocity.Clients.Helpjuice)
end
