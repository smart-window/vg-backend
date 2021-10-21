defmodule Velocity.Contexts.MeetingsTest do
  use Velocity.DataCase

  alias Velocity.Contexts.Meetings

  describe "meetings" do
    alias Velocity.Schema.Meeting

    @valid_attrs %{
      description: "some description",
      meeting_date: ~D[2010-04-17],
      notes: "some notes"
    }
    @update_attrs %{
      description: "some updated description",
      meeting_date: ~D[2011-05-18],
      notes: "some updated notes"
    }
    @invalid_attrs %{description: nil, meeting_date: nil, notes: nil}

    def meeting_fixture(attrs \\ %{}) do
      {:ok, meeting} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Meetings.create_meeting()

      meeting
    end

    test "list_meetings/0 returns all meetings" do
      meeting = meeting_fixture()
      assert Meetings.list_meetings() == [meeting]
    end

    test "get_meeting!/1 returns the meeting with given id" do
      meeting = meeting_fixture()
      assert Meetings.get_meeting!(meeting.id) == meeting
    end

    test "create_meeting/1 with valid data creates a meeting" do
      assert {:ok, %Meeting{} = meeting} = Meetings.create_meeting(@valid_attrs)
      assert meeting.description == "some description"
      assert meeting.meeting_date == ~D[2010-04-17]
      assert meeting.notes == "some notes"
    end

    test "create_meeting/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Meetings.create_meeting(@invalid_attrs)
    end

    test "update_meeting/2 with valid data updates the meeting" do
      meeting = meeting_fixture()
      assert {:ok, %Meeting{} = meeting} = Meetings.update_meeting(meeting.id, @update_attrs)
      assert meeting.description == "some updated description"
      assert meeting.meeting_date == ~D[2011-05-18]
      assert meeting.notes == "some updated notes"
    end

    test "update_meeting/2 with invalid data returns error changeset" do
      meeting = meeting_fixture()
      assert {:error, %Ecto.Changeset{}} = Meetings.update_meeting(meeting.id, @invalid_attrs)
      assert meeting == Meetings.get_meeting!(meeting.id)
    end

    test "delete_meeting/1 deletes the meeting" do
      meeting = meeting_fixture()
      assert {:ok, %Meeting{}} = Meetings.delete_meeting(meeting.id)
      assert_raise Ecto.NoResultsError, fn -> Meetings.get_meeting!(meeting.id) end
    end
  end
end
