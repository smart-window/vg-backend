defmodule Velocity.Repo.Migrations.AddStatusTypesToDocuments do
  use Ecto.Migration

  def change do
    DocumentStatusEnum.create_type()

    execute """
     alter table documents alter column status type document_status_type USING status::document_status_type
    """

    execute """
      alter table documents alter status SET DEFAULT 'not_started'
    """
  end
end
