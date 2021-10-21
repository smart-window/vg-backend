defmodule VelocityWeb.Schema.TrainingTypes do
  @moduledoc false
  use Absinthe.Schema.Notation

  @desc "training"
  object :training do
    field :id, :id
    field :name, :string
    field :description, :string
    field :bundle_url, :string
    field :employee_trainings, list_of(:employee_training)
  end

  @desc "employee training"
  object :employee_training do
    field :id, :id
    field :training_id, :id
    field :user_id, :id
    field :due_date, :date
    field :status, :string
    field :completed_date, :date
  end

  @desc "employee training report item"
  object :employee_training_report_item do
    field :id, :id
    field :due_date, :date
    field :status, :string
    field :completed_date, :date
    field :training_name, :string
    field :user_full_name, :string
    field :user_last_name, :string
    field :user_client_name, :string
    field :user_work_address_country_name, :string
    field :sql_row_count, :integer
  end

  @desc "training country"
  object :training_country do
    field :id, :id
    field :country_id, :id
    field :training_id, :id
  end

  @desc "employee trainings report"
  object :employee_trainings_report do
    field :row_count, :integer
    field :employee_training_report_items, list_of(:employee_training_report_item)
  end
end
