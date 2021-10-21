defmodule VelocityWeb.Resolvers.Processes do
  @moduledoc """
  GQL resolver for processes
  """

  alias Velocity.Contexts.Processes

  def get(args = %{id: id}, _) do
    {:ok, Processes.filter(id, args)}
  end

  def create(%{process_template_id: process_template_id, service_ids: service_ids}, _) do
    Processes.create(process_template_id, service_ids)
  end

  def create_for_template_name(
        %{process_template_name: process_template_name, service_names: service_names},
        _
      ) do
    Processes.create_for_template_name(process_template_name, service_names)
  end

  def all(_, _) do
    Processes.all()
  end

  def add_process_role_users(%{process_id: process_id, role_id: role_id, user_ids: user_ids}, _) do
    Processes.add_process_role_users(process_id, role_id, user_ids)
  end

  def remove_process_role_users(
        %{process_id: process_id, role_id: role_id, user_ids: user_ids},
        _
      ) do
    Processes.remove_process_role_users(process_id, role_id, user_ids)
  end

  def add_services(%{process_id: process_id, service_ids: service_ids}, _) do
    Processes.add_services(
      String.to_integer(process_id),
      Enum.map(service_ids, &String.to_integer/1)
    )
  end

  def remove_services(%{process_id: process_id, service_ids: service_ids}, _) do
    Processes.remove_services(
      String.to_integer(process_id),
      Enum.map(service_ids, &String.to_integer/1)
    )
  end
end
