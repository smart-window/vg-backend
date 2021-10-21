defmodule VelocityWeb.Resolvers.TimeTrackersTest do
  use VelocityWeb.ConnCase, async: true

  @time_entries_query """
    query($startDate: Date!, $endDate: Date!) {
      timeEntries(startDate: $startDate, endDate: $endDate) {
        id
        eventDate
        description
        totalHours
        timeTypeId
        userId
        timePolicyId
        timeType {
          id
          slug
        }
      }
    }
  """

  def setup_employment(user) do
    # set up an employment for the user
    partner = Factory.insert(:partner)
    client = Factory.insert(:client)
    job = Factory.insert(:job, %{client: client})
    contract = Factory.insert(:contract, %{client: client})
    country_of_employment = Factory.insert(:country)
    employee = Factory.insert(:employee, %{user: user})

    Factory.insert(:employment, %{
      effective_date: "2020-01-01",
      partner: partner,
      employee: employee,
      job: job,
      contract: contract,
      country: country_of_employment
    })
  end

  describe "query :time_entries" do
    test "it returns the time_entries for the current user", %{conn: conn} do
      time_policy = Factory.insert(:time_policy)
      user = Factory.insert(:user, %{current_time_policy_id: time_policy.id})
      employment = setup_employment(user)

      Factory.insert_list(3, :time_entry, %{
        user_id: user.id,
        time_policy_id: time_policy.id,
        employment_id: employment.id,
        event_date: "2020-11-24"
      })

      Factory.insert(:time_entry, %{
        user_id: user.id,
        time_policy_id: time_policy.id,
        employment_id: employment.id,
        event_date: "2020-12-24"
      })

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @time_entries_query,
          variables: %{
            startDate: "2020-09-10",
            endDate: "2020-11-30"
          }
        })
        |> json_response(200)

      assert %{"data" => %{"timeEntries" => time_entries}} = response
      assert length(time_entries) == 3
    end
  end

  @time_entries_report_query """
    query(
      $pageSize: Int!
      $sortColumn: String!
      $sortDirection: String!
      $lastId: ID
      $lastValue: String
      $filterBy: [FilterBy]
      $searchBy: String
    ) {
      timeEntriesReport(
        pageSize: $pageSize
        sortColumn: $sortColumn
        sortDirection: $sortDirection
        lastId: $lastId
        lastValue: $lastValue
        filterBy: $filterBy
        searchBy: $searchBy
      ) {
        row_count
        time_entry_report_items {
          id
          description
          eventDate
          totalHours
          timeTypeSlug
          userClientName
          userFullName
          userWorkAddressCountryName
        }
      }
    }
  """

  describe "query :time_entries_report" do
    test "it returns all time entries for an admin user", %{conn: conn} do
      # set up customer (who logged the entries)
      time_policy = Factory.insert(:time_policy)
      customer = Factory.insert(:user, %{current_time_policy_id: time_policy.id})
      employment = setup_employment(customer)
      customers_group = Factory.insert(:group, %{slug: "customers", okta_group_slug: "Customers"})
      Factory.insert(:user_group, %{user_id: customer.id, group_id: customers_group.id})

      # allow the backend to select the employment to use
      Factory.insert_list(3, :time_entry, %{
        user_id: customer.id,
        time_policy_id: time_policy.id,
        employment_id: employment.id,
        event_date: "2020-11-24"
      })

      # set up admin user
      admin_user = Factory.insert(:user)
      admin_group = Factory.insert(:group, %{slug: "admin", okta_group_slug: "PegaAdmins"})
      Factory.insert(:user_group, %{user_id: admin_user.id, group_id: admin_group.id})

      Factory.insert(:role, %{slug: "employee-reporting"})

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", admin_user.okta_user_uid)
        |> post("/graphql", %{
          query: @time_entries_report_query,
          variables: %{
            sortColumn: "eventDate",
            sortDirection: "desc",
            pageSize: 10
          }
        })
        |> json_response(200)

      assert %{
               "data" => %{
                 "timeEntriesReport" => %{
                   "row_count" => row_count,
                   "time_entry_report_items" => _time_entries
                 }
               }
             } = response

      assert row_count == 3
    end

    test "it returns restricted time entries for a user with an external assignment", %{
      conn: conn
    } do
      # set up customer time entry
      time_policy = Factory.insert(:time_policy)
      customer = Factory.insert(:user, %{current_time_policy_id: time_policy.id})
      customer_employment = setup_employment(customer)
      customers_group = Factory.insert(:group, %{slug: "customers", okta_group_slug: "Customers"})
      Factory.insert(:user_group, %{user_id: customer.id, group_id: customers_group.id})

      Factory.insert(:time_entry, %{
        user_id: customer.id,
        time_policy_id: time_policy.id,
        employment_id: customer_employment.id,
        event_date: "2020-11-24"
      })

      # Set up non-customer time entry
      non_customer = Factory.insert(:user, %{current_time_policy_id: time_policy.id})
      non_customer_employment = setup_employment(non_customer)

      Factory.insert(:time_entry, %{
        user_id: non_customer.id,
        time_policy_id: time_policy.id,
        employment_id: non_customer_employment.id,
        event_date: "2020-12-24"
      })

      # set up user with external assignment
      internal_user = Factory.insert(:user)
      csr_group = Factory.insert(:group, %{slug: "csr", okta_group_slug: "CSR"})
      Factory.insert(:user_group, %{user_id: internal_user.id, group_id: csr_group.id})

      reporting_role = Factory.insert(:role, %{slug: "employee-reporting"})

      Factory.insert(:role_assignment, %{
        user_id: internal_user.id,
        role_id: reporting_role.id,
        assignment_type: "external"
      })

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", internal_user.okta_user_uid)
        |> post("/graphql", %{
          query: @time_entries_report_query,
          variables: %{
            sortColumn: "eventDate",
            sortDirection: "desc",
            pageSize: 10
          }
        })
        |> json_response(200)

      assert %{
               "data" => %{
                 "timeEntriesReport" => %{
                   "row_count" => row_count,
                   "time_entry_report_items" => _time_entries
                 }
               }
             } = response

      assert row_count == 2
    end
  end

  @create_time_entry_mutation """
    mutation CreateTimeEntry($eventDate: Date!, $totalHours: Float!, $description: String!, $timeTypeId: ID!) {
      createTimeEntry(eventDate: $eventDate, totalHours: $totalHours, description: $description, timeTypeId: $timeTypeId) {
        id
        eventDate
        description
        totalHours
        timeTypeId
        userId
        timePolicy {
          id
          slug
        }
        timeType {
          id
          slug
        }
      }
    }
  """

  @delete_time_entry_mutation """
    mutation DeleteTimeEntry($id: ID!) {
      deleteTimeEntry(id: $id) {
        id
      }
    }
  """
  describe "mutation :time_entries" do
    test "it creates a time_entry for the current user", %{conn: conn} do
      time_type = Factory.insert(:time_type)
      time_policy = Factory.insert(:time_policy)
      user = Factory.insert(:user, %{current_time_policy_id: time_policy.id})
      setup_employment(user)

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @create_time_entry_mutation,
          variables: %{
            eventDate: "2020-09-10",
            totalHours: 4,
            description: "todo",
            timeTypeId: time_type.id
          }
        })
        |> json_response(200)

      assert %{"data" => %{"createTimeEntry" => time_entry}} = response
      assert time_entry["totalHours"] == 4
      assert time_entry["timeType"]["id"] != nil
      assert time_entry["timePolicy"]["id"] != nil
    end

    test "it creates a time_entry for the current user even if the user doesn't have a current time policy",
         %{conn: conn} do
      time_type = Factory.insert(:time_type)
      Factory.insert(:time_policy)
      user = Factory.insert(:user)
      setup_employment(user)

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @create_time_entry_mutation,
          variables: %{
            eventDate: "2020-09-10",
            totalHours: 4,
            description: "todo",
            timeTypeId: time_type.id
          }
        })
        |> json_response(200)

      assert %{"data" => %{"createTimeEntry" => time_entry}} = response
      assert time_entry["totalHours"] == 4
      assert time_entry["timeType"]["id"] != nil
      assert time_entry["timePolicy"]["id"] != nil
    end

    test "it deletes a time_entry with given id", %{conn: conn} do
      time_policy = Factory.insert(:time_policy)
      user = Factory.insert(:user, %{current_time_policy_id: time_policy.id})
      employment = setup_employment(user)

      time_entry =
        Factory.insert(:time_entry, %{
          user_id: user.id,
          employment_id: employment.id,
          time_policy_id: time_policy.id
        })

      time_entry_id = time_entry.id

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @delete_time_entry_mutation,
          variables: %{
            id: time_entry_id
          }
        })
        |> json_response(200)

      time_entry_id_string = to_string(time_entry_id)
      assert %{"data" => %{"deleteTimeEntry" => %{"id" => ^time_entry_id_string}}} = response
    end
  end

  @edit_time_entry_mutation """
    mutation EditTimeEntry($id: ID!, $totalHours: Float!, $description: String!, $timeTypeId: ID!) {
      editTimeEntry(id: $id, totalHours: $totalHours, description: $description, timeTypeId: $timeTypeId) {
        id
        eventDate
        description
        totalHours
        timeTypeId
        userId
        timePolicyId
        timeType {
          id
          slug
        }
      }
    }
  """
  describe "update :time_entries" do
    test "it edits a time_entry for the current user", %{conn: conn} do
      time_type = Factory.insert(:time_type)
      time_policy = Factory.insert(:time_policy)
      user = Factory.insert(:user, %{current_time_policy_id: time_policy.id})
      employment = setup_employment(user)

      time_entry_to_edit =
        Factory.insert(:time_entry, %{
          user_id: user.id,
          time_policy_id: time_policy.id,
          employment_id: employment.id,
          event_date: "2020-11-24",
          total_hours: 4
        })

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @edit_time_entry_mutation,
          variables: %{
            id: time_entry_to_edit.id,
            totalHours: 8,
            description: "",
            timeTypeId: time_type.id,
            eventDate: "2020-11-24"
          }
        })
        |> json_response(200)

      assert %{"data" => %{"editTimeEntry" => time_entry}} = response
      assert time_entry["totalHours"] == 8
      assert String.to_integer(time_entry["timeTypeId"]) == time_type.id
    end
  end

  @time_types_query """
    query {
      timeTypes {
        id
        slug
      }
    }
  """

  describe "query :time_types query" do
    test "it returns a list of time types according to time policy id", %{conn: conn} do
      time_policy = Factory.insert(:time_policy)

      user = Factory.insert(:user, %{current_time_policy_id: time_policy.id})

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @time_types_query
        })
        |> json_response(200)

      assert %{"data" => %{"timeTypes" => _time_types}} = response
    end
  end

  @all_time_types_query """
    query {
      allTimeTypes {
        id
        slug
      }
    }
  """

  describe "query :all_time_types query" do
    test "it returns a list of time types according to time policy id", %{conn: conn} do
      time_policy = Factory.insert(:time_policy)
      user = Factory.insert(:user, %{current_time_policy_id: time_policy.id})

      Factory.insert_list(3, :time_type)

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @all_time_types_query
        })
        |> json_response(200)

      assert %{"data" => %{"allTimeTypes" => all_time_types}} = response
      assert Enum.count(all_time_types) == 3
    end
  end
end
