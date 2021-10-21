defmodule Velocity.Contexts.TeamTagsTest do
  use Velocity.DataCase

  alias Velocity.Contexts.Tags
  alias Velocity.Contexts.Teams
  alias Velocity.Contexts.TeamTags

  describe "team_tags" do
    alias Velocity.Schema.TeamTag

    @team_attrs %{
      name: "some team"
    }
    @tag_attrs %{name: "some tag"}

    def team_fixture(attrs \\ %{}) do
      {:ok, team} =
        attrs
        |> Enum.into(@team_attrs)
        |> Teams.create_team()

      team
    end

    def tag_fixture(attrs \\ %{}) do
      {:ok, tag} =
        attrs
        |> Enum.into(@tag_attrs)
        |> Tags.create_tag()

      tag
    end

    def team_tag_fixture(attrs \\ %{}) do
      team = team_fixture()
      tag = tag_fixture()

      {:ok, team_tag} =
        attrs
        |> Enum.into(%{team: team, tag: tag})
        |> TeamTags.create_team_tag()

      team_tag
    end

    test "get_team_tag!/1 returns the team_tag with given id" do
      team_tag = team_tag_fixture()
      assert TeamTags.get_team_tag!(team_tag.id) == team_tag
    end

    test "create_team_tag/1 with valid data creates a team_tag" do
      assert {:ok, %TeamTag{} = _team_tag} =
               TeamTags.create_team_tag(%{
                 team: team_fixture(),
                 tag: tag_fixture()
               })
    end

    test "create_team_tag/1 with invalid data returns error changeset" do
      assert_raise Postgrex.Error, fn ->
        TeamTags.create_team_tag(%{
          team: team_fixture(),
          tag: nil
        })
      end
    end

    test "delete_team_tag/1 deletes the team_tag" do
      team_tag = team_tag_fixture()
      assert {:ok, %TeamTag{}} = TeamTags.delete_team_tag(team_tag.id)
      assert_raise Ecto.NoResultsError, fn -> TeamTags.get_team_tag!(team_tag.id) end
    end
  end
end
