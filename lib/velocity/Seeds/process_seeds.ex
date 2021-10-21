defmodule Velocity.Seeds.ProcessSeeds do
  alias Velocity.Contexts.Processes
  alias Velocity.Repo
  alias Velocity.Schema.EmailTemplate
  alias Velocity.Schema.HTMLSection
  alias Velocity.Schema.ProcessTemplate
  alias Velocity.Schema.Service
  alias Velocity.Schema.StageTemplate
  alias Velocity.Schema.TaskTemplate

  def create do
    inserted_and_updated_at = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    {_, [service | _]} =
      Repo.insert_all(
        Service,
        [
          %{
            name: "Time Tracking",
            inserted_at: inserted_and_updated_at,
            updated_at: inserted_and_updated_at
          },
          %{
            name: "Payroll",
            inserted_at: inserted_and_updated_at,
            updated_at: inserted_and_updated_at
          },
          %{
            name: "PTO",
            inserted_at: inserted_and_updated_at,
            updated_at: inserted_and_updated_at
          },
          %{
            name: "CRM",
            inserted_at: inserted_and_updated_at,
            updated_at: inserted_and_updated_at
          }
        ],
        returning: true
      )

    process_template_ids =
      Enum.map(
        [
          %{
            type: "onboarding"
          },
          %{
            type: "offboarding"
          },
          %{
            type: "launch"
          }
        ],
        fn process_template_args ->
          changeset = ProcessTemplate.changeset(%ProcessTemplate{}, process_template_args)

          process_template = Repo.insert!(changeset)

          {_, stage_templates} =
            Repo.insert_all(
              StageTemplate,
              [
                %{
                  name: "Do the the thing",
                  order: 1,
                  process_template_id: process_template.id,
                  inserted_at: inserted_and_updated_at,
                  updated_at: inserted_and_updated_at
                },
                %{
                  name: "You are getting it",
                  order: 2,
                  process_template_id: process_template.id,
                  inserted_at: inserted_and_updated_at,
                  updated_at: inserted_and_updated_at
                },
                %{
                  name: "Finished",
                  order: 3,
                  process_template_id: process_template.id,
                  inserted_at: inserted_and_updated_at,
                  updated_at: inserted_and_updated_at
                }
              ],
              returning: true
            )

          # credo:disable-for-lines:1
          Enum.map(stage_templates, fn stage_template ->
            Repo.insert_all(TaskTemplate, [
              %{
                name:
                  Enum.random([
                    "Rengar",
                    "Slicer",
                    "Ninja",
                    "Cow",
                    "Robot",
                    "Dingo",
                    "Lux",
                    "Yasuo",
                    "Hecarim",
                    "Garen",
                    "Demacia",
                    "Draven"
                  ]),
                type: Enum.random(TaskTemplate.task_types()),
                stage_template_id: stage_template.id,
                order: Enum.random([1, 2, 3, 4, 5]),
                completion_type: "check_off",
                service_id: service.id,
                knowledge_article_urls: [
                  "https://kb.velocityglobal.com/98080-independent-contractor-risk/independent-contractor-risk-colombia"
                ],
                inserted_at: inserted_and_updated_at,
                updated_at: inserted_and_updated_at
              }
            ])
          end)

          # temporary for email task template, delete before merging
          {_, [email_template | _]} =
            Repo.insert_all(
              EmailTemplate,
              [
                %{
                  name: Faker.Pokemon.name(),
                  subject: "New Email",
                  inserted_at: inserted_and_updated_at,
                  updated_at: inserted_and_updated_at
                }
              ],
              returning: true
            )

          Repo.insert_all(HTMLSection, [
            %{
              html: "Hello",
              order: 1,
              email_template_id: email_template.id,
              inserted_at: inserted_and_updated_at,
              updated_at: inserted_and_updated_at
            }
          ])

          Repo.insert_all(TaskTemplate, [
            %{
              name: "Email task",
              type: TaskTemplate.task_type(:email_template),
              context: %{id: email_template.id},
              stage_template_id: List.first(stage_templates).id,
              order: Enum.random([1, 2, 3, 4, 5]),
              completion_type: "check_off",
              service_id: service.id,
              knowledge_article_urls: [
                "https://kb.velocityglobal.com/98080-independent-contractor-risk/independent-contractor-risk-colombia"
              ],
              inserted_at: inserted_and_updated_at,
              updated_at: inserted_and_updated_at
            }
          ])

          process_template.id
        end
      )

    Enum.each(process_template_ids, fn process_template_id ->
      Processes.create(process_template_id, [service.id])
    end)
  end
end
