defmodule Velocity.Seeds.DocumentSeeds do
  alias Velocity.Repo
  alias Velocity.Schema.DocumentTemplateCategory

  def create do
    inserted_and_updated_at = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    user_doc_types_map = [
      %{slug: "Expenses Documents"},
      %{slug: "Employee Documents"},
      %{slug: "Payslip Documents"},
      %{slug: "Visa/Immigration Documents"},
      %{slug: "Partner Documents"},
      %{slug: "Internal Documents"},
      %{slug: "Time Tracking Documents"},
      %{slug: "Contract Documents"},
      %{slug: "Payslips Documents"}
    ]

    client_doc_types_map = [
      %{slug: "General"},
      %{slug: "SOW"},
      %{slug: "Certifications"},
      %{slug: "Contracts"}
    ]

    user_doc_types_params =
      Enum.map(user_doc_types_map, fn doc_item ->
        %{
          slug: doc_item.slug,
          entity_type: :employee,
          inserted_at: inserted_and_updated_at,
          updated_at: inserted_and_updated_at
        }
      end)

    client_doc_types_params =
      Enum.map(client_doc_types_map, fn doc_item ->
        %{
          slug: doc_item.slug,
          entity_type: :client,
          inserted_at: inserted_and_updated_at,
          updated_at: inserted_and_updated_at
        }
      end)

    doc_types_params = user_doc_types_params ++ client_doc_types_params

    {_num, _doc_types} =
      Repo.insert_all(DocumentTemplateCategory, doc_types_params,
        on_conflict: {:replace, [:entity_type]},
        conflict_target: :slug,
        returning: true
      )
  end
end
