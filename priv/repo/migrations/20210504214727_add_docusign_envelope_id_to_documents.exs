defmodule Velocity.Repo.Migrations.AddDocusignEnvelopeIdToDocuments do
  use Ecto.Migration

  def change do
    alter table(:documents) do
      add :docusign_envelope_id, :string
    end
  end
end
