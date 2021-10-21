defmodule Velocity.Repo.Migrations.AddColumnsToClients do
  use Ecto.Migration

  def change do
    ClientSegmentTypeEnum.create_type()
    PaymentTypeEnum.create_type()

    alter table(:clients) do
      add :timezone, :string
      add :segment, ClientSegmentTypeEnum.type()
      add :industry_vertical, :string
      add :international_market_operating_experience, :string
      add :other_peo_experience, :string
      add :expansion_goals, :string
      add :previous_solutions, :string
      add :goals_and_expectations, :string
      add :pain_points_and_challenges, :string
      add :special_onboarding_instructions, :string
      add :interaction_highlights, :text
      add :interaction_challenges, :text
      add :partner_referral, :string
      add :partner_stakeholder, :string
      add :other_referral_information, :string
      add :standard_payment_terms, :string
      add :payment_type, PaymentTypeEnum.type()
      add :pricing_structure, :string
      add :pricing_notes, :string
      add :salesforce_id, :string
      add :netsuite_id, :string
    end
  end
end
