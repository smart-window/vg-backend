defmodule Velocity.Contexts.ProcessTemplates do
  alias Velocity.Repo
  alias Velocity.Schema.DependentTask
  alias Velocity.Schema.DependentTaskTemplate
  alias Velocity.Schema.Form
  alias Velocity.Schema.FormFormField
  # alias Velocity.Schema.KnowledgeArticle
  alias Velocity.Schema.Process
  alias Velocity.Schema.ProcessService
  alias Velocity.Schema.ProcessTemplate
  # alias Velocity.Schema.ProcessTemplateKnowledgeArticle
  alias Velocity.Schema.Role
  alias Velocity.Schema.Service
  alias Velocity.Schema.Stage
  alias Velocity.Schema.StageTemplate
  alias Velocity.Schema.StageTemplateKnowledgeArticle
  alias Velocity.Schema.Task
  alias Velocity.Schema.TaskAssignment
  alias Velocity.Schema.TaskTemplate
  alias Velocity.Schema.TaskTemplateRole
  alias Velocity.Schema.TaskTemplateRoleNotification

  import Ecto.Query

  require Logger

  @doc """
  Returns the list of process templates.

  ## Examples

      iex> list_process_templates()
      [%ProcessTemplate{}, ...]

  """
  def list_process_templates do
    Repo.all(ProcessTemplate)
  end

  # credo:disable-for-this-file Credo.Check.Refactor.Nesting

  def import(process_templates) do
    Repo.transaction(fn ->
      Enum.reduce(process_templates, [], fn process_template_config, templates_acc ->
        inserted_and_updated_at =
          NaiveDateTime.utc_now()
          |> NaiveDateTime.truncate(:second)

        services = Repo.all(Service)
        template_name = Map.fetch!(process_template_config, :name)

        Repo.insert(
          %ProcessTemplate{
            type: template_name,
            inserted_at: inserted_and_updated_at,
            updated_at: inserted_and_updated_at
          },
          on_conflict: :nothing
        )

        process_template = Repo.get_by(ProcessTemplate, type: template_name)
        # collect existing (if any) stage templates and task templates
        stage_template_ids =
          from(st in StageTemplate,
            select: st.id,
            where: st.process_template_id == ^process_template.id
          )
          |> Repo.all()
          |> Enum.into([])

        task_template_ids =
          from(tt in TaskTemplate,
            select: tt.id,
            where: tt.stage_template_id in ^stage_template_ids
          )
          |> Repo.all()
          |> Enum.into([])

        # NOTE: doesn't appear as if these are being used (they have no id, etc.)
        # delete any existing process template knowledge articles
        # from(ptka in ProcessTemplateKnowledgeArticle, where: ptka.process_template_id == ^process_template.id)
        # |> Repo.delete_all()
        # add specified process template knowledge articles if any
        # Enum.each(Map.get(process_template_config, :knowledge_articles, []), fn knowledge_article_url ->
        #  knowledge_article = case Repo.get_by(KnowledgeArticle, url: knowledge_article_url) do
        #    nil ->
        #      {:ok, ka} = Repo.insert(%KnowledgeArticle{
        #        url: knowledge_article_url,
        #        inserted_at: inserted_and_updated_at,
        #        updated_at: inserted_and_updated_at
        #      })
        #      ka
        #    ka -> ka
        #  end
        #  Repo.insert(%ProcessTemplateKnowledgeArticle{
        #    process_template_id: process_template.id,
        #    knowledge_article_id: knowledge_article.id
        #  })
        # end)

        # process stages from import
        acc =
          Map.fetch!(process_template_config, :stages)
          |> Enum.with_index()
          |> Enum.reduce(%{order: 1, stage_template_ids: [], task_template_ids: []}, fn {stage,
                                                                                         stage_index},
                                                                                        acc ->
            stage_name = Map.fetch!(stage, :name)

            Repo.insert(
              %StageTemplate{
                name: stage_name,
                order: stage_index + 1,
                process_template_id: process_template.id,
                inserted_at: inserted_and_updated_at,
                updated_at: inserted_and_updated_at
              },
              on_conflict: :nothing
            )

            stage_template =
              Repo.get_by(StageTemplate,
                name: stage_name,
                process_template_id: process_template.id
              )

            # NOTE: doesn't appear as if these are not used (no id, etc.)
            # delete any existing stage template knowledge articles
            # from(stka in StageTemplateKnowledgeArticle, where: stka.stage_template_id == ^stage_template.id)
            # |> Repo.delete_all()
            # add specified stage template knowledge articles if any
            # Enum.each(Map.get(stage, :knowledge_articles, []), fn knowledge_article_url ->
            #  knowledge_article = case Repo.get_by(KnowledgeArticle, url: knowledge_article_url) do
            #    nil ->
            #      {:ok, ka} = Repo.insert(%KnowledgeArticle{
            #        url: knowledge_article_url,
            #        inserted_at: inserted_and_updated_at,
            #        updated_at: inserted_and_updated_at
            #      })
            #      ka
            #    ka -> ka
            #  end
            #  Repo.insert(%StageTemplateKnowledgeArticle{
            #    stage_template_id: stage_template.id,
            #    knowledge_article_id: knowledge_article.id
            #  })
            # end)

            acc =
              Map.fetch!(stage, :tasks)
              |> Enum.with_index()
              |> Enum.reduce(acc, fn {task, _task_index}, acc ->
                task_name = Map.fetch!(task, :name)
                service_name = Map.fetch!(task, :service)
                knowledge_article_urls = Map.get(task, :knowledge_article_urls, [])

                knowledge_article_search_terms =
                  Map.get(task, :knowledge_article_search_terms, [])

                service = Enum.find(services, fn service -> service.name == service_name end)

                if service == nil do
                  raise "service #{service_name} not found"
                end

                # create or update the task template
                {:ok, task_template} =
                  case Repo.get_by(TaskTemplate,
                         name: task_name,
                         stage_template_id: stage_template.id
                       ) do
                    nil -> %TaskTemplate{}
                    tt -> tt |> Repo.preload([:stage_template, :service])
                  end
                  |> TaskTemplate.changeset(%{
                    order: acc.order,
                    name: task_name,
                    context: Map.get(task, :context, nil),
                    completion_type: Map.fetch!(task, :completion_type),
                    type: Map.fetch!(task, :type),
                    service: service,
                    stage_template: stage_template,
                    knowledge_article_urls: knowledge_article_urls,
                    knowledge_article_search_terms: knowledge_article_search_terms,
                    inserted_at: inserted_and_updated_at,
                    updated_at: inserted_and_updated_at
                  })
                  |> Repo.insert_or_update()

                # delete any roles currently assigned
                from(ttr in TaskTemplateRole, where: ttr.task_template_id == ^task_template.id)
                |> Repo.delete_all()

                # add specified roles (if any)
                Enum.each(Map.get(task, :roles, []), fn role ->
                  role = Repo.get_by!(Role, slug: role)

                  Repo.insert(%TaskTemplateRole{
                    task_template: task_template,
                    role: role,
                    inserted_at: inserted_and_updated_at,
                    updated_at: inserted_and_updated_at
                  })
                end)

                # delete any notification roles currently assigned
                from(ttrn in TaskTemplateRoleNotification,
                  where: ttrn.task_template_id == ^task_template.id
                )
                |> Repo.delete_all()

                # add specified notification roles (if any)
                Enum.each(Map.get(task, :notification_roles, []), fn role ->
                  role = Repo.get_by!(Role, slug: role)

                  Repo.insert(%TaskTemplateRoleNotification{
                    task_template: task_template,
                    role: role,
                    inserted_at: inserted_and_updated_at,
                    updated_at: inserted_and_updated_at
                  })
                end)

                # delete any existing dependencies
                from(dtt in DependentTaskTemplate,
                  where: dtt.task_template_id == ^task_template.id
                )
                |> Repo.delete_all()

                # add specified dependencies if any
                Enum.each(Map.get(task, :depends_on, []), fn depends_on ->
                  dependent_task_template =
                    Repo.get_by!(TaskTemplate,
                      name: depends_on,
                      stage_template_id: stage_template.id
                    )

                  Repo.insert(%DependentTaskTemplate{
                    task_template: task_template,
                    dependent_task_template: dependent_task_template,
                    inserted_at: inserted_and_updated_at,
                    updated_at: inserted_and_updated_at
                  })
                end)

                %{
                  order: acc.order + 1,
                  stage_template_ids: acc.stage_template_ids,
                  task_template_ids: acc.task_template_ids ++ [task_template.id]
                }
              end)

            %{
              order: acc.order,
              stage_template_ids: acc.stage_template_ids ++ [stage_template.id],
              task_template_ids: acc.task_template_ids
            }
          end)

        tasks_to_be_deleted = task_template_ids -- acc.task_template_ids
        delete_tasks(tasks_to_be_deleted)
        delete_task_templates(tasks_to_be_deleted)
        stage_templates_to_be_deleted = stage_template_ids -- acc.stage_template_ids
        delete_stages(stage_templates_to_be_deleted)
        delete_stage_templates(stage_templates_to_be_deleted)
        migrate_processes(process_template)
        templates_acc ++ [process_template]
      end)
    end)
  end

  defp delete_tasks(task_template_ids) do
    task_ids =
      from(t in Task,
        select: t.id,
        where: t.task_template_id in ^task_template_ids
      )
      |> Repo.all()
      |> Enum.into([])

    from(fff in FormFormField,
      join: f in assoc(fff, :form),
      where: f.task_id in ^task_ids
    )
    |> Repo.delete_all()

    from(f in Form, where: f.task_id in ^task_ids)
    |> Repo.delete_all()

    from(dt in DependentTask,
      where: dt.task_id in ^task_ids or dt.dependent_task_id in ^task_ids
    )
    |> Repo.delete_all()

    from(ta in TaskAssignment, where: ta.task_id in ^task_ids)
    |> Repo.delete_all()

    from(t in Task, where: t.id in ^task_ids)
    |> Repo.delete_all()
  end

  defp delete_task_templates(task_template_ids) do
    from(ttg in TaskTemplateRole, where: ttg.task_template_id in ^task_template_ids)
    |> Repo.delete_all()

    from(ttg in TaskTemplateRoleNotification, where: ttg.task_template_id in ^task_template_ids)
    |> Repo.delete_all()

    from(dtt in DependentTaskTemplate,
      where:
        dtt.task_template_id in ^task_template_ids or
          dtt.dependent_task_template_id in ^task_template_ids
    )
    |> Repo.delete_all()

    from(tt in TaskTemplate, where: tt.id in ^task_template_ids)
    |> Repo.delete_all()
  end

  defp delete_stages(stage_template_ids) do
    from(s in Stage, where: s.stage_template_id in ^stage_template_ids)
    |> Repo.delete_all()
  end

  defp delete_stage_templates(stage_template_ids) do
    from(stka in StageTemplateKnowledgeArticle,
      where: stka.stage_template_id in ^stage_template_ids
    )
    |> Repo.delete_all()

    from(st in StageTemplate, where: st.id in ^stage_template_ids)
    |> Repo.delete_all()
  end

  defp migrate_processes(process_template) do
    process_template =
      process_template
      |> Repo.preload(stage_templates: :task_templates)

    process_ids =
      from(p in Process,
        select: p.id,
        where: p.process_template_id == ^process_template.id
      )
      |> Repo.all()
      |> Enum.into([])

    process_ids
    |> Enum.each(fn process_id ->
      migrate_process(process_template, process_id)
    end)
  end

  defp migrate_process(process_template, process_id) do
    from(ps in ProcessService, where: ps.process_id == ^process_id)
    |> Repo.delete_all()

    inserted_and_updated_at =
      NaiveDateTime.utc_now()
      |> NaiveDateTime.truncate(:second)

    acc =
      Enum.reduce(process_template.stage_templates, %{service_ids: []}, fn stage_template, acc ->
        # create or update the stage
        {:ok, stage} =
          case Repo.get_by(Stage, process_id: process_id, stage_template_id: stage_template.id) do
            nil -> %Stage{}
            t -> t
          end
          |> Stage.changeset(%{
            name: stage_template.name,
            percent_complete: 0.0,
            process_id: process_id,
            stage_template_id: stage_template.id,
            inserted_at: inserted_and_updated_at,
            updated_at: inserted_and_updated_at
          })
          |> Repo.insert_or_update()

        acc =
          Enum.reduce(stage_template.task_templates, acc, fn task_template, acc ->
            # create or update the task
            {:ok, _task} =
              case Repo.get_by(Task, process_id: process_id, task_template_id: task_template.id) do
                nil -> %Task{}
                t -> t
              end
              |> Task.changeset(%{
                order: task_template.order,
                stage_id: stage.id,
                process_id: process_id,
                service_id: task_template.service_id,
                task_template_id: task_template.id,
                status: "not_started",
                completion_type: task_template.completion_type,
                type: task_template.type,
                inserted_at: inserted_and_updated_at,
                updated_at: inserted_and_updated_at
              })
              |> Repo.insert_or_update()

            %{
              service_ids: acc.service_ids ++ [task_template.service_id]
            }
          end)

        %{
          service_ids: acc.service_ids
        }
      end)

    # ensure all process services exist
    acc.service_ids
    |> Enum.uniq()
    |> Enum.each(fn service_id ->
      Repo.insert(%ProcessService{
        process_id: process_id,
        service_id: service_id,
        inserted_at: inserted_and_updated_at,
        updated_at: inserted_and_updated_at
      })
    end)

    # update all task dependencies now that all tasks exist
    process =
      Process
      |> Repo.get!(process_id)
      |> Repo.preload(stages: [tasks: [task_template: :dependent_task_templates]])

    all_tasks = Enum.flat_map(process.stages, fn stage -> stage.tasks end)

    Enum.each(process.stages, fn stage ->
      Enum.each(stage.tasks, fn task ->
        # delete any existing dependencies
        from(dt in DependentTask, where: dt.task_id == ^task.id)
        |> Repo.delete_all()

        # add specified dependencies if any
        Enum.each(task.task_template.dependent_task_templates, fn dependent_task_template ->
          dependent_task =
            Enum.find(all_tasks, fn task ->
              task.task_template_id == dependent_task_template.id
            end)

          if dependent_task == nil do
            raise "no task for task dependency #{dependent_task_template.name} found"
          end

          Repo.insert(%DependentTask{
            task_id: task.id,
            dependent_task_id: dependent_task.id,
            inserted_at: inserted_and_updated_at,
            updated_at: inserted_and_updated_at
          })
        end)
      end)
    end)
  end
end
