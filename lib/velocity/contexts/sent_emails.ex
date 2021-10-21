defmodule Velocity.Contexts.SentEmails do
  @moduledoc """
  The Contexts.SentEmails context.
  """

  import Ecto.Query, warn: false
  alias Velocity.Repo

  alias Velocity.Schema.ClientSentEmail
  alias Velocity.Schema.SentEmail

  @doc """
  Returns the list of sent_emails.

  ## Examples

      iex> list_sent_emails()
      [%SentEmail{}, ...]

  """
  def list_sent_emails do
    Repo.all(SentEmail)
    |> Repo.preload(:sent_email_users)
  end

  @doc """
  Gets a single sent_email.

  Raises if the Sent email does not exist.

  ## Examples

      iex> get_sent_email!(123)
      %SentEmail{}

  """
  def get_sent_email!(id), do: Repo.get!(SentEmail, id) |> Repo.preload(sent_email_users: :user)

  @doc """
  Creates a sent_email.

  ## Examples

      iex> create_sent_email(%{field: value})
      {:ok, %SentEmail{}}

      iex> create_sent_email(%{field: bad_value})
      {:error, ...}

  """
  def create_sent_email(attrs \\ %{}) do
    %SentEmail{}
    |> SentEmail.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a sent_email.

  ## Examples

      iex> update_sent_email(sent_email, %{field: new_value})
      {:ok, %SentEmail{}}

      iex> update_sent_email(sent_email, %{field: bad_value})
      {:error, ...}

  """
  def update_sent_email(id, attrs) do
    Repo.get!(SentEmail, id)
    |> SentEmail.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a SentEmail.

  ## Examples

      iex> delete_sent_email(sent_email)
      {:ok, %SentEmail{}}

      iex> delete_sent_email(sent_email)
      {:error, ...}

  """
  def delete_sent_email(id) do
    %SentEmail{id: id}
    |> Repo.delete()
  end

  def upsert_client_sent_email(args) do
    if id = Map.get(args, :id) do
      client_sent_email = Repo.get!(ClientSentEmail, id) |> Repo.preload(:sent_email)
      SentEmail.changeset(client_sent_email.sent_email, args) |> Repo.update()
      {:ok, client_sent_email}
    else
      {:ok, sent_email} = SentEmail.changeset(%SentEmail{}, args) |> Repo.insert()

      ClientSentEmail.changeset(
        %ClientSentEmail{},
        %{client_id: args.client_id, sent_email_id: sent_email.id}
      )
      |> Repo.insert()
    end
  end

  def delete_client_sent_email(id) do
    %ClientSentEmail{id: id} |> Repo.delete()
  end
end
