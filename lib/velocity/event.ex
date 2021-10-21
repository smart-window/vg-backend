defmodule Velocity.Event do
  @moduledoc """
  An 'event' represents something that happened in the system.

  Events run in an asyncronous process and always return :ok
  All events will be audited
  Events can optionally trigger notifications.
  """

  alias Velocity.Notifications

  @events [:pto_request_submitted, :task_completed]

  def occurred(event_name, meta, opts \\ [async: true]) when event_name in @events do
    Notifications.schedule(event_name, meta, opts)

    # AuditTrail.log(event_name, meta)
  end

  def events do
    @events
  end

  defmodule Metadata do
    @moduledoc """
    provides the structure for event metadata
    """
    defstruct [:user, :event_time]
  end
end
