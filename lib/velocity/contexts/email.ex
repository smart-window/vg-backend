defmodule Velocity.Contexts.Email do
  @moduledoc """
  Context for sending emails
  """

  import Bamboo.Email
  alias Ecto.Multi
  alias Velocity.Notifications.Adapters.Email.Mailer
  alias Velocity.Repo
  alias Velocity.Schema.SentEmail
  alias Velocity.Schema.SentEmailDocument
  alias Velocity.Schema.SentEmailUser
  alias Velocity.Schema.TaskSentEmail
  require Logger

  def send(params) do
    # supports list
    to = Map.get(params, :to, [])
    # single only
    from = Map.get(params, :from)
    # supports list
    cc = Map.get(params, :cc, [])
    # supports list
    bcc = Map.get(params, :bcc, [])
    subject = Map.get(params, :subject)
    body = Map.get(params, :body)
    description = Map.get(params, :description)
    attachment_payloads = Map.get(params, :attachments, [])

    send_date =
      NaiveDateTime.utc_now()
      |> NaiveDateTime.truncate(:second)

    # create a sent email and associated entities
    {:ok, multi_result} =
      Multi.new()
      |> Multi.insert(
        :sent_email,
        SentEmail.changeset(%SentEmail{}, %{
          body: body,
          description: description,
          sent_date: send_date,
          subject: subject
        })
      )
      |> Multi.insert_all(:sent_email_users, SentEmailUser, fn %{sent_email: sent_email} ->
        build_sent_email_user_list([from], "from", sent_email.id, send_date) ++
          build_sent_email_user_list(to, "to", sent_email.id, send_date) ++
          build_sent_email_user_list(cc, "cc", sent_email.id, send_date) ++
          build_sent_email_user_list(bcc, "bcc", sent_email.id, send_date)
      end)
      |> Multi.insert_all(:sent_email_documents, SentEmailDocument, fn %{sent_email: sent_email} ->
        Enum.map(attachment_payloads, fn attachment ->
          {document_id, ""} = Integer.parse(attachment.document_id)

          %{
            sent_email_id: sent_email.id,
            document_id: document_id,
            inserted_at: send_date,
            updated_at: send_date
          }
        end)
      end)
      |> Repo.transaction()

    associate_sent_email(
      multi_result.sent_email.id,
      send_date,
      Map.get(params, :association_type),
      Map.get(params, :association_id)
    )

    new_email()
    |> to(build_recipient_list(to))
    |> cc(build_recipient_list(cc))
    |> bcc(build_recipient_list(bcc))
    |> from(build_recipient(from))
    |> subject(subject)
    |> text_body(body)
    |> html_body(body)
    |> build_attachments(attachment_payloads)
    |> Mailer.deliver_now()

    multi_result.sent_email.id
  end

  defp build_sent_email_user_list(nil, _recipient_type, _sent_email_id, _send_date) do
    []
  end

  defp build_sent_email_user_list(recipients, recipient_type, sent_email_id, send_date) do
    Enum.map(recipients, fn recipient ->
      user_id =
        if recipient.user_id != nil do
          {user_id, ""} = Integer.parse(recipient.user_id)
          user_id
        else
          nil
        end

      %{
        sent_email_id: sent_email_id,
        email_address: recipient.email_address,
        user_id: user_id,
        recipient_type: recipient_type,
        inserted_at: send_date,
        updated_at: send_date
      }
    end)
  end

  defp build_recipient_list(nil) do
    []
  end

  defp build_recipient_list(recipients) do
    Enum.map(recipients, fn recipient ->
      build_recipient(recipient)
    end)
  end

  defp build_recipient(recipient) do
    recipient.email_address
  end

  defp build_attachments(email_struct, attachment_payloads)
       when is_nil(attachment_payloads) or attachment_payloads == [] do
    email_struct
  end

  defp build_attachments(email_struct, attachment_payloads) do
    attachment_payloads =
      attachment_payloads
      |> Enum.map(fn attachment ->
        case HTTPoison.get(attachment.url) do
          {:ok, %{body: data}} ->
            %Bamboo.Attachment{
              content_type: attachment.content_type,
              filename: attachment.filename,
              data: data
            }

          error ->
            Logger.error(
              "Unable to retrieve attachment from url: #{inspect(error)} ::: #{
                inspect(attachment)
              }"
            )

            nil
        end
      end)

    attachment_payloads
    |> Enum.reject(&(&1 == nil))
    |> Enum.reduce(email_struct, fn attachment, email ->
      put_attachment(email, attachment)
    end)
  end

  defp associate_sent_email(_sent_email_id, _inserted_and_updated_at, nil, _) do
    # nothing to associate
  end

  defp associate_sent_email(sent_email_id, inserted_and_updated_at, "task", association_id) do
    Repo.insert(
      TaskSentEmail.changeset(%TaskSentEmail{}, %{
        task_id: association_id,
        sent_email_id: sent_email_id,
        inserted_at: inserted_and_updated_at,
        updated_at: inserted_and_updated_at
      })
    )
  end
end
