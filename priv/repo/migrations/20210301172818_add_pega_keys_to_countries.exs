defmodule Velocity.Repo.Migrations.AddPegaKeysToCountries do
  use Ecto.Migration

  def change do
    alter table(:countries) do
      add :pega_pk, :string
      add :pega_ak, :string
      add :iso_alpha_3_code, :string, size: 3
    end
  end
end
