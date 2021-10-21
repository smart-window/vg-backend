defmodule Velocity.Contexts.Docusign do
  @moduledoc """
    Context which interfaces with the docusign Rest API.
    Currently proxies requests and delegates JWT generation to this library:
    https://github.com/neilberkman/docusign_elixir
  """
  alias DocuSign.Api
  alias Velocity.Repo
  alias Velocity.Schema.Document

  require Logger

  @doc """
    Generates a one-time signing URL for an end user to sign an assigned Document
  """
  def signing_url(document, user, redirect_uri) do
    {:ok, envelope} = create_envelope(user, document.docusign_template_id)
    # Associate new envelope with our Document record
    {:ok, updated_document} =
      Document.changeset(document, %{docusign_envelope_id: envelope.envelopeId}) |> Repo.update()

    get_envelope_embedded_url(user, updated_document, redirect_uri)
  end

  @doc """
    Generates a one-time viewing URL for a document that has already been signed
  """
  def recipient_view_url(document, user, redirect_uri) do
    get_envelope_embedded_url(user, document, redirect_uri)
  end

  @spec create_envelope(Velocity.Schema.User, String.t()) ::
          {:ok, DocuSign.Model.EnvelopeDefinition.t()} | {:error, binary}
  defp create_envelope(user, template_id) do
    Logger.debug("Preparing envelopes...")

    template_role = %DocuSign.Model.TemplateRole{
      clientUserId: user.okta_user_uid,
      name: user.full_name,
      email: user.email,
      # IMPORTANT: this must match a client name under template recipients
      # We could look into fetching this in the future
      roleName: "Velocity Global"
    }

    # Create envelope definition from template. Commented fields are for creation without template.
    definition = %DocuSign.Model.EnvelopeDefinition{
      # TODO: what should this subject be? Default is like "Please DocuSign: sample.pdf."
      # emailSubject: "Please sign this document sent from Elixir SDK",
      templateId: template_id,
      templateRoles: [template_role],
      # recipients: recipients,
      # documents: documents,
      status: "sent"
    }

    Logger.debug("Creating envelope...")

    case Api.Envelopes.envelopes_post_envelopes(connection(), account_id(),
           envelopeDefinition: definition
         ) do
      {:ok, %DocuSign.Model.EnvelopeSummary{} = envelope_summary} ->
        Logger.debug("Envelope has been sent:")
        Logger.debug(envelope_summary)
        {:ok, envelope_summary}

      {:error, %Tesla.Env{body: error}} ->
        Logger.error(inspect(error))
        {:error, error}
    end
  end

  # Generates a one-time URL to embed a new envelope in the Client UI.
  @spec get_envelope_embedded_url(
          Velocity.Schema.User,
          Velocity.Schema.Document,
          String.t()
        ) ::
          {:ok, String} | {:error, binary}
  defp get_envelope_embedded_url(user, document, redirect_uri) do
    # Create docusign recipient view request (step 4 here: https://developers.docusign.com/docs/esign-rest-api/how-to/request-signature-in-app-embedded)
    # API docs: https://developers.docusign.com/docs/esign-rest-api/reference/envelopes/envelopeviews/createrecipient/

    # Create recipient view request struct
    view_request_options = %DocuSign.Model.RecipientViewRequest{
      # TODO: this should be hooked up to a React callback route
      # currently called like http://localhost:8080/docusign/callback?event=signing_complete
      returnUrl:
        Application.get_env(:velocity, :docusign_callback_url) <>
          "?documentId=#{document.id}&redirectUri=#{redirect_uri}",

      # Describes how our app has authenticated the user
      authenticationMethod: "SingleSignOn_Other",

      # Recipient information must match embedded recipient info
      # we used to create the envelope.

      # This needs to be unique per-envelope
      clientUserId: user.okta_user_uid,
      # this needs to be unique per-user
      recipientId: user.id,
      userName: user.full_name,
      email: user.email
      # TODO: understand this better - used to keep client session alive
      # NOTE: The pings will only be sent if the pingUrl is an https address
      # pingUrl: args.dsPingUrl; // optional setting
      # pingFrequency: 600
    }

    # Make actual api CreateView request
    case Api.EnvelopeViews.views_post_envelope_recipient_view(
           connection(),
           account_id(),
           document.docusign_envelope_id,
           recipientViewRequest: view_request_options
         ) do
      {:ok, %DocuSign.Model.EnvelopeViews{} = envelope_view} ->
        Logger.debug("Envelope view has been created:")
        Logger.debug(envelope_view)
        {:ok, envelope_view.url}

      {:error, %Tesla.Env{body: error}} ->
        Logger.error(inspect(error))
        {:error, error}
    end
  end

  defp connection, do: DocuSign.Connection.new(client: DocuSign.APIClient.client())
  defp account_id, do: Application.get_env(:docusign, :account_id)
end
