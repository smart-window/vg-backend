defmodule VelocityWeb.Schema.SentEmailTypes do
  @moduledoc false
  use Absinthe.Schema.Notation

  alias Velocity.Repo

  @desc "sent_email"
  object :sent_email do
    field :id, :id
    field :body, :string
    field :description, :string
    field :sent_date, :naive_datetime
    field :subject, :string
    field :sent_email_users, list_of(:sent_email_user)
  end

  object :sent_email_user do
    field :email_address, :string
    field :recipient_type, :string
    field :sent_email, :sent_email
    field :user, :user
  end

  object :client_sent_email do
    field :id, :id

    field(:client, :client) do
      resolve(fn client_sent_email, _args, _info ->
        client = Ecto.assoc(client_sent_email, :client) |> Repo.one()
        {:ok, client}
      end)
    end

    field(:sent_email, :sent_email) do
      resolve(fn client_sent_email, _args, _info ->
        sent_email = Ecto.assoc(client_sent_email, :sent_email) |> Repo.one()
        {:ok, sent_email}
      end)
    end
  end
end
