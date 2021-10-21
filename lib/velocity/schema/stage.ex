defmodule Velocity.Schema.Stage do
  @moduledoc """
  A stage is a swimlane or grouping of tasks
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Velocity.Schema.Process
  alias Velocity.Schema.StageTemplate
  alias Velocity.Schema.Task

  schema "stages" do
    field :name, :string
    field :percent_complete, :float
    belongs_to :process, Process
    belongs_to :stage_template, StageTemplate
    has_many :tasks, Task

    timestamps()
  end

  @doc false
  def changeset(stage, attrs) do
    stage
    |> cast(attrs, [:percent_complete, :name, :process_id, :stage_template_id])
    |> validate_required([:percent_complete])
  end
end
