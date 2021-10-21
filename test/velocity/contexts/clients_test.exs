defmodule Velocity.Contexts.ClientsTest do
  use Velocity.DataCase

  alias Velocity.Contexts.Clients

  describe "clients" do
    alias Velocity.Schema.Client

    @valid_attrs %{
      expansion_goals: "some expansion_goals",
      goals_and_expectations: "some goals_and_expectations",
      industry_vertical: "some industry_vertical",
      interaction_challenges: "some interaction_challenges",
      interaction_highlights: "some interaction_highlights",
      international_market_operating_experience: "some international_market_operating_experience",
      name: "some name",
      netsuite_id: "some netsuite_id",
      other_peo_experience: "some other_peo_experience",
      other_referral_information: "some other_referral_information",
      pain_points_and_challenges: "some pain_points_and_challenges",
      partner_referral: "some partner_referral",
      partner_stakeholder: "some partner_stakeholder",
      payment_type: "ach",
      pega_ak: "some pega_ak",
      pega_pk: "some pega_pk",
      previous_solutions: "some previous_solutions",
      pricing_notes: "some pricing_notes",
      pricing_structure: "some pricing_structure",
      salesforce_id: "some salesforce_id",
      segment: "standard_peo",
      special_onboarding_instructions: "some special_onboarding_instructions",
      standard_payment_terms: "some standard_payment_terms",
      timezone: "some timezone"
    }
    @update_attrs %{
      expansion_goals: "some updated expansion_goals",
      goals_and_expectations: "some updated goals_and_expectations",
      industry_vertical: "some updated industry_vertical",
      interaction_challenges: "some updated interaction_challenges",
      interaction_highlights: "some updated interaction_highlights",
      international_market_operating_experience:
        "some updated international_market_operating_experience",
      name: "some updated name",
      netsuite_id: "some updated netsuite_id",
      other_peo_experience: "some updated other_peo_experience",
      other_referral_information: "some updated other_referral_information",
      pain_points_and_challenges: "some updated pain_points_and_challenges",
      partner_referral: "some updated partner_referral",
      partner_stakeholder: "some updated partner_stakeholder",
      payment_type: "wire",
      pega_ak: "some updated pega_ak",
      pega_pk: "some updated pega_pk",
      previous_solutions: "some updated previous_solutions",
      pricing_notes: "some updated pricing_notes",
      pricing_structure: "some updated pricing_structure",
      salesforce_id: "some updated salesforce_id",
      segment: "expansion",
      special_onboarding_instructions: "some updated special_onboarding_instructions",
      standard_payment_terms: "some updated standard_payment_terms",
      timezone: "some updated timezone"
    }
    @invalid_attrs %{
      expansion_goals: nil,
      goals_and_expectations: nil,
      industry_vertical: nil,
      interaction_challenges: nil,
      interaction_highlights: nil,
      international_market_operating_experience: nil,
      name: nil,
      netsuite_id: nil,
      other_peo_experience: nil,
      other_referral_information: nil,
      pain_points_and_challenges: nil,
      partner_referral: nil,
      partner_stakeholder: nil,
      payment_type: nil,
      pega_ak: nil,
      pega_pk: nil,
      previous_solutions: nil,
      pricing_notes: nil,
      pricing_structure: nil,
      salesforce_id: nil,
      segment: nil,
      special_onboarding_instructions: nil,
      standard_payment_terms: nil,
      timezone: nil
    }

    def client_fixture(attrs \\ %{}) do
      {:ok, client} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Clients.create_client()

      client
    end

    test "list_clients/0 returns all clients" do
      client = client_fixture()
      assert Clients.list_clients() == [client]
    end

    test "get_client!/1 returns the client with given id" do
      client = client_fixture()
      assert Clients.get_client!(client.id) == client
    end

    test "create_client/1 with valid data creates a client" do
      assert {:ok, %Client{} = client} = Clients.create_client(@valid_attrs)
      assert client.expansion_goals == "some expansion_goals"
      assert client.goals_and_expectations == "some goals_and_expectations"
      assert client.industry_vertical == "some industry_vertical"
      assert client.interaction_challenges == "some interaction_challenges"
      assert client.interaction_highlights == "some interaction_highlights"

      assert client.international_market_operating_experience ==
               "some international_market_operating_experience"

      assert client.name == "some name"
      assert client.netsuite_id == "some netsuite_id"
      assert client.other_peo_experience == "some other_peo_experience"
      assert client.other_referral_information == "some other_referral_information"
      assert client.pain_points_and_challenges == "some pain_points_and_challenges"
      assert client.partner_referral == "some partner_referral"
      assert client.partner_stakeholder == "some partner_stakeholder"
      assert client.payment_type == :ach
      assert client.pega_ak == "some pega_ak"
      assert client.pega_pk == "some pega_pk"
      assert client.previous_solutions == "some previous_solutions"
      assert client.pricing_notes == "some pricing_notes"
      assert client.pricing_structure == "some pricing_structure"
      assert client.salesforce_id == "some salesforce_id"
      assert client.segment == :standard_peo
      assert client.special_onboarding_instructions == "some special_onboarding_instructions"
      assert client.standard_payment_terms == "some standard_payment_terms"
      assert client.timezone == "some timezone"
    end

    test "create_client/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Clients.create_client(@invalid_attrs)
    end

    test "update_client/2 with valid data updates the client" do
      client = client_fixture()
      assert {:ok, %Client{} = client} = Clients.update_client(client.id, @update_attrs)
      assert client.expansion_goals == "some updated expansion_goals"
      assert client.goals_and_expectations == "some updated goals_and_expectations"
      assert client.industry_vertical == "some updated industry_vertical"
      assert client.interaction_challenges == "some updated interaction_challenges"
      assert client.interaction_highlights == "some updated interaction_highlights"

      assert client.international_market_operating_experience ==
               "some updated international_market_operating_experience"

      assert client.name == "some updated name"
      assert client.netsuite_id == "some updated netsuite_id"
      assert client.other_peo_experience == "some updated other_peo_experience"
      assert client.other_referral_information == "some updated other_referral_information"
      assert client.pain_points_and_challenges == "some updated pain_points_and_challenges"
      assert client.partner_referral == "some updated partner_referral"
      assert client.partner_stakeholder == "some updated partner_stakeholder"
      assert client.payment_type == :wire
      assert client.pega_ak == "some updated pega_ak"
      assert client.pega_pk == "some updated pega_pk"
      assert client.previous_solutions == "some updated previous_solutions"
      assert client.pricing_notes == "some updated pricing_notes"
      assert client.pricing_structure == "some updated pricing_structure"
      assert client.salesforce_id == "some updated salesforce_id"
      assert client.segment == :expansion

      assert client.special_onboarding_instructions ==
               "some updated special_onboarding_instructions"

      assert client.standard_payment_terms == "some updated standard_payment_terms"
      assert client.timezone == "some updated timezone"
    end

    test "update_client/2 with invalid data returns error changeset" do
      client = client_fixture()
      assert {:error, %Ecto.Changeset{}} = Clients.update_client(client.id, @invalid_attrs)
      assert client == Clients.get_client!(client.id)
    end

    test "delete_client/1 deletes the client" do
      client = client_fixture()
      assert {:ok, %Client{}} = Clients.delete_client(client.id)
      assert_raise Ecto.NoResultsError, fn -> Clients.get_client!(client.id) end
    end

    test "change_client/1 returns a client changeset" do
      client = client_fixture()
      assert %Ecto.Changeset{} = Clients.change_client(client)
    end
  end
end
