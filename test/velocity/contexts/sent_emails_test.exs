defmodule Velocity.Contexts.SentEmailsTest do
  use Velocity.DataCase

  alias Velocity.Contexts.SentEmails

  describe "sent_emails" do
    alias Velocity.Schema.SentEmail

    @valid_attrs %{
      body: "some body",
      description: "some description",
      sent_date: ~N[2010-04-17T00:00:00],
      subject: "some subject"
    }
    @update_attrs %{
      body: "some updated body",
      description: "some updated description",
      sent_date: ~N[2011-05-18T00:00:00],
      subject: "some updated subject"
    }
    @invalid_attrs %{body: nil, description: nil, sent_date: nil, subject: nil}

    def sent_email_fixture(attrs \\ %{}) do
      {:ok, sent_email} =
        attrs
        |> Enum.into(@valid_attrs)
        |> SentEmails.create_sent_email()

      sent_email |> Repo.preload(:sent_email_users)
    end

    test "list_sent_emails/0 returns all sent_emails" do
      sent_email = sent_email_fixture()
      assert SentEmails.list_sent_emails() == [sent_email]
    end

    test "get_sent_email!/1 returns the sent_email with given id" do
      sent_email = sent_email_fixture()
      assert SentEmails.get_sent_email!(sent_email.id) == sent_email
    end

    test "create_sent_email/1 with valid data creates a sent_email" do
      assert {:ok, %SentEmail{} = sent_email} = SentEmails.create_sent_email(@valid_attrs)
      assert sent_email.body == "some body"
      assert sent_email.description == "some description"
      assert sent_email.sent_date == ~N[2010-04-17 00:00:00]
      assert sent_email.subject == "some subject"
    end

    test "create_sent_email/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = SentEmails.create_sent_email(@invalid_attrs)
    end

    test "update_sent_email/2 with valid data updates the sent_email" do
      sent_email = sent_email_fixture()

      assert {:ok, %SentEmail{} = sent_email} =
               SentEmails.update_sent_email(sent_email.id, @update_attrs)

      assert sent_email.body == "some updated body"
      assert sent_email.description == "some updated description"
      assert sent_email.sent_date == ~N[2011-05-18 00:00:00]
      assert sent_email.subject == "some updated subject"
    end

    test "update_sent_email/2 with invalid data returns error changeset" do
      sent_email = sent_email_fixture()

      assert {:error, %Ecto.Changeset{}} =
               SentEmails.update_sent_email(sent_email.id, @invalid_attrs)

      assert sent_email == SentEmails.get_sent_email!(sent_email.id)
    end

    test "delete_sent_email/1 deletes the sent_email" do
      sent_email = sent_email_fixture()
      assert {:ok, %SentEmail{}} = SentEmails.delete_sent_email(sent_email.id)
      assert_raise Ecto.NoResultsError, fn -> SentEmails.get_sent_email!(sent_email.id) end
    end
  end
end
