defmodule Velocity.Contexts.MeetingUsersTest do
  use Velocity.DataCase

  alias Velocity.Contexts.Meetings
  alias Velocity.Contexts.MeetingUsers
  alias Velocity.Contexts.Users

  describe "meeting_users" do
    alias Velocity.Schema.MeetingUser

    @meeting_attrs %{
      description: "some description",
      meeting_date: ~D[2010-04-17],
      notes: "some notes"
    }
    @user_attrs %{email: "test@fubar.com", okta_user_uid: "abcdefh"}

    def meeting_fixture(attrs \\ %{}) do
      {:ok, meeting} =
        attrs
        |> Enum.into(@meeting_attrs)
        |> Meetings.create_meeting()

      meeting
    end

    def user_fixture(attrs \\ %{country_specific_fields: %{}, settings: %{"language" => "en"}}) do
      {:ok, user} =
        attrs
        |> Enum.into(@user_attrs)
        |> Users.create()

      user
    end

    def meeting_user_fixture(attrs \\ %{}) do
      meeting = meeting_fixture()
      user = user_fixture()

      {:ok, meeting_user} =
        attrs
        |> Enum.into(%{meeting: meeting, user: user})
        |> MeetingUsers.create_meeting_user()

      meeting_user
    end

    test "get_meeting_user!/1 returns the meeting_user with given id" do
      meeting_user = meeting_user_fixture()
      assert MeetingUsers.get_meeting_user!(meeting_user.id) == meeting_user
    end

    test "create_meeting_user/1 with valid data creates a meeting_user" do
      assert {:ok, %MeetingUser{} = _meeting_user} =
               MeetingUsers.create_meeting_user(%{
                 meeting: meeting_fixture(),
                 user: user_fixture()
               })
    end

    test "create_meeting_user/1 with invalid data returns error changeset" do
      assert_raise Postgrex.Error, fn ->
        MeetingUsers.create_meeting_user(%{meeting: meeting_fixture(%{}), user: nil})
      end
    end

    test "delete_meeting_user/1 deletes the meeting_user" do
      meeting_user = meeting_user_fixture()
      assert {:ok, %MeetingUser{}} = MeetingUsers.delete_meeting_user(meeting_user.id)
      assert_raise Ecto.NoResultsError, fn -> MeetingUsers.get_meeting_user!(meeting_user.id) end
    end
  end
end
