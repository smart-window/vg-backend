defmodule Velocity.Seeds.PermissionsSeeds do
  alias Velocity.Repo
  alias Velocity.Schema.Group
  alias Velocity.Schema.GroupPermission
  alias Velocity.Schema.Permission
  alias Velocity.Schema.Role
  alias Velocity.Schema.User
  alias Velocity.Schema.UserGroup

  @doc """
    Creates all groups, roles, and associated permissions.
  """
  def create do
    inserted_and_updated_at = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    # Groups and Roles
    groups_map = [
      {"admin", "PegaAdmins"},
      {"csr", "CSR"},
      {"it-department", "IT Department"},
      {"customers", "Customers"},
      {"client-manager", "ClientManager"},
      {"partner", "ICPManager"}
    ]

    group_params =
      Enum.map(groups_map, fn {slug, okta_group_slug} ->
        %{
          slug: slug,
          okta_group_slug: okta_group_slug,
          inserted_at: inserted_and_updated_at,
          updated_at: inserted_and_updated_at
        }
      end)

    {_num, groups} =
      Repo.insert_all(Group, group_params,
        on_conflict: [set: [updated_at: inserted_and_updated_at]],
        conflict_target: :slug,
        returning: true
      )

    role_slugs = [
      "ClientAccountAssociate",
      "ClientAccountManager",
      "ClientFinanceManager",
      "Executive",
      "HRManager",
      "HRSpecialist",
      "ImmigrationAssociate",
      "ImmigrationManager",
      "Leadership",
      "NetworkTeam",
      "PTOManager",
      "PartnerManager",
      "PayrollTeam",
      "RegionalAccountAssociate",
      "RegionalAccountManager",
      "RegionalDirector",
      "SeniorManager"
    ]

    role_params =
      Enum.map(role_slugs, fn slug ->
        %{
          slug: slug,
          inserted_at: inserted_and_updated_at,
          updated_at: inserted_and_updated_at
        }
      end)

    {_num, _roles} =
      Repo.insert_all(Role, role_params,
        on_conflict: [set: [updated_at: inserted_and_updated_at]],
        conflict_target: :slug,
        returning: true
      )

    internal_permission_slugs = [
      "admin-tools",
      "companies",
      "document-management",
      "knowledge-management",
      "notifications",
      "onboarding",
      "pto",
      "supported-employees",
      "time-tracking",
      "time-off",
      "process",
      "payroll",
      "user-management",
      "view-internal-comments"
    ]

    cm_permission_slugs = [
      "manage-employees-map",
      "manage-employees-list"
    ]

    ee_permission_slugs = [
      "my-profile",
      "my-work-information",
      "my-time-off",
      "my-payroll",
      "my-documents",
      "ee-onboarding",
      "training",
      "view-external-comments"
    ]

    partner_permission_slugs = [
      # TODO
    ]

    permissions_params =
      Enum.map(
        internal_permission_slugs,
        fn perm ->
          %{
            slug: perm,
            inserted_at: inserted_and_updated_at,
            updated_at: inserted_and_updated_at
          }
        end
      )

    cm_permission_params =
      Enum.map(
        cm_permission_slugs,
        fn perm ->
          %{
            slug: perm,
            inserted_at: inserted_and_updated_at,
            updated_at: inserted_and_updated_at
          }
        end
      )

    ee_permission_params =
      Enum.map(
        ee_permission_slugs,
        fn perm ->
          %{
            slug: perm,
            inserted_at: inserted_and_updated_at,
            updated_at: inserted_and_updated_at
          }
        end
      )

    all_permissions_params = permissions_params ++ ee_permission_params ++ cm_permission_params

    {_num, permissions} =
      Repo.insert_all(Permission, all_permissions_params,
        on_conflict: [set: [updated_at: inserted_and_updated_at]],
        conflict_target: :slug,
        returning: true
      )

    admin_group = Enum.find(groups, &(&1.slug == "admin"))
    admin_slugs = internal_permission_slugs

    it_department_group = Enum.find(groups, &(&1.slug == "it-department"))
    it_department_slugs = internal_permission_slugs

    csr_group = Enum.find(groups, &(&1.slug == "csr"))
    csr_slugs = internal_permission_slugs -- ["pto"]

    customers_group = Enum.find(groups, &(&1.slug == "customers"))
    customers_slugs = ee_permission_slugs ++ ["pto-request", "upload-documents", "training"]

    cm_group = Enum.find(groups, &(&1.slug == "client-manager"))
    cm_slugs = cm_permission_slugs

    partner_group = Enum.find(groups, &(&1.slug == "partner"))
    partner_slugs = partner_permission_slugs

    group_permissions = %{
      it_department_group.id =>
        permissions
        |> Enum.filter(fn %{slug: slug} ->
          Enum.member?(it_department_slugs, slug)
        end)
        |> Enum.map(& &1.id),
      admin_group.id =>
        permissions
        |> Enum.filter(fn %{slug: slug} ->
          Enum.member?(admin_slugs, slug)
        end)
        |> Enum.map(& &1.id),
      csr_group.id =>
        permissions
        |> Enum.filter(fn %{slug: slug} ->
          Enum.member?(csr_slugs, slug)
        end)
        |> Enum.map(& &1.id),
      customers_group.id =>
        permissions
        |> Enum.filter(fn %{slug: slug} ->
          Enum.member?(customers_slugs, slug)
        end)
        |> Enum.map(& &1.id),
      cm_group.id =>
        permissions
        |> Enum.filter(fn %{slug: slug} ->
          Enum.member?(cm_slugs, slug)
        end)
        |> Enum.map(& &1.id),
      partner_group.id =>
        permissions
        |> Enum.filter(fn %{slug: slug} ->
          Enum.member?(partner_slugs, slug)
        end)
        |> Enum.map(& &1.id)
    }

    group_permssions_params =
      Enum.reduce(group_permissions, [], fn {group_id, permission_ids}, acc ->
        group_perms =
          Enum.map(permission_ids, fn perm_id ->
            %{
              group_id: group_id,
              permission_id: perm_id,
              inserted_at: inserted_and_updated_at,
              updated_at: inserted_and_updated_at
            }
          end)

        group_perms ++ acc
      end)

    Repo.insert_all(GroupPermission, group_permssions_params,
      on_conflict: [set: [updated_at: inserted_and_updated_at]],
      conflict_target: [:permission_id, :group_id]
    )

    # Dev / Sandbox permission seeds
    if Application.get_env(:velocity, :compile_env) == :dev do
      create_dev_seeds(groups, inserted_and_updated_at)
    end
  end

  defp create_dev_seeds(groups, inserted_and_updated_at) do
    # hard coded list of uids from env dev-283105-admin
    okta_user_uids = [
      "00u3i0diimUjiujnk357",
      "00u56by5adUjq9uMc357",
      "00u4x6c15bsOtTAmh357",
      "00u2ik7j9n1xcGmqc357",
      "00u5ca653ud0TdCbX357",
      "00u7wsytk0PoRM79i357"
    ]

    Enum.map(okta_user_uids, fn okta_user_uid ->
      user_changeset =
        User.build(%{
          email: okta_user_uid <> "@fake.com",
          okta_user_uid: okta_user_uid
        })

      user =
        Repo.insert!(user_changeset,
          on_conflict: [set: [updated_at: inserted_and_updated_at]],
          conflict_target: [:okta_user_uid],
          returning: true
        )

      Enum.each(groups, fn group ->
        user_group_changeset = UserGroup.changeset(%UserGroup{}, %{group: group, user: user})

        Repo.insert!(user_group_changeset,
          on_conflict: :nothing,
          conflict_target: [:user_id, :group_id]
        )
      end)
    end)
  end
end
