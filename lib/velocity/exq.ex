defmodule Velocity.Exq do
  @moduledoc """
  callback for Exq behaviour for Mox testing
  """
  @callback enqueue_at(Exq.t(), String.t(), DateTime.t(), Module.t(), list()) ::
              {:ok, any()} | {:error, any()}
end
