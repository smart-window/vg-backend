defmodule Velocity.Utils do
  @moduledoc """
    Utils are a collections of commonly modules re-used throughout the Velocity directories
  """
  defmodule Errors do
    @moduledoc """
      Helpful functions for working with errors
    """

    require Logger
    alias Velocity.Utils.Changesets, as: Utils

    def mapify_error({:error, error}) do
      mapify_error(error)
    end

    def mapify_error(error = %Ecto.Changeset{}) do
      Utils.traverse_errors(error)
    end

    def mapify_error(error) when is_map(error) do
      error
    end

    def mapify_error(error) when is_binary(error) do
      %{message: error}
    end

    def mapify_error(errors) when is_list(errors) do
      Enum.map(errors, &mapify_error(&1))
    end

    def mapify_error(error) do
      inspect(error)
    end
  end

  defmodule Changesets do
    @moduledoc """
      Helpful functions for working with changesets
    """
    import Ecto.Changeset, only: [traverse_errors: 2, put_assoc: 4]

    def traverse_errors(changeset) do
      traverse_errors(changeset, fn {msg, opts} ->
        Enum.reduce(opts, msg, fn
          {key, value}, acc when is_list(value) ->
            String.replace(acc, "%{#{key}}", inspect(value))

          {key, value}, acc ->
            String.replace(acc, "%{#{key}}", to_string(value))
        end)
      end)
    end

    # https://elixirforum.com/t/using-put-assoc-in-models-changeset-2/34343
    def maybe_put_assoc(changeset, assoc, attrs \\ %{}, opts \\ [required: true]) do
      if resource = attrs[to_string(assoc)] || attrs[assoc] do
        put_assoc(changeset, assoc, resource, opts)
      else
        changeset
      end
    end
  end

  defmodule Dates do
    @moduledoc false
    def parse_pega_date!(pega_data_string) do
      pega_data_string
      |> Timex.parse!("%Y%m%d", :strftime)
      |> NaiveDateTime.to_date()
    end

    def is_date?(%Date{}) do
      true
    end

    def is_date?(_) do
      false
    end
  end

  defmodule Math do
    @moduledoc false

    def round(float) when is_float(float) do
      Float.round(float, 2)
    end

    def round(integer) when is_integer(integer) do
      integer
    end
  end

  defmodule TupleEncoder do
    @moduledoc false

    defimpl Jason.Encoder, for: Tuple do
      def encode(data, options) when is_tuple(data) do
        data
        |> Tuple.to_list()
        |> Jason.Encoder.List.encode(options)
      end
    end
  end
end
