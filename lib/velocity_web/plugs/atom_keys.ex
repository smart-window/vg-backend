defmodule VelocityWeb.Plugs.AtomKeys do
  @moduledoc """
  plug to transform params to atom keys
  """
  @behaviour Plug

  require Logger
  def init(options), do: options

  def call(conn, _opts) do
    atom_params = AtomicMap.convert(conn.params, safe: false)
    Logger.info("params: #{inspect(atom_params)}")
    Map.put(conn, :params, atom_params)
  end
end
