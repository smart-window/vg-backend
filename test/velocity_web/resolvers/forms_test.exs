defmodule VelocityWeb.Resolvers.FormsTest do
  use VelocityWeb.ConnCase, async: true

  alias Velocity.EmploymentHelpers
  alias Velocity.Repo
  alias Velocity.Schema.Address
  alias Velocity.Schema.User

  @form_fields_query """
    query($formSlug: ID!) {
      formFieldsForCurrentUser(formSlug: $formSlug) {
        id
        slug
        country_id
        optional
        config
        value
      }
    }
  """

  describe "query :form_fields_for_current_user" do
    test "it returns a form_field with overrides and a value for the given current user and form",
         %{conn: conn} do
      country = Factory.insert(:country)
      address = Factory.insert(:address, %{country_id: country.id})

      user =
        Factory.insert(:user, %{
          avatar_url: "http://foo.bar",
          work_address_id: address.id
        })

      EmploymentHelpers.setup_employment(user, country)

      form = Factory.insert(:form)

      form_field =
        Factory.insert(:form_field, %{
          slug: "field1",
          optional: true,
          source_table: "users",
          source_table_field: "avatar_url",
          config: %{attribute1: "val1"}
        })

      _form_form_field =
        Factory.insert(:form_form_field, %{
          form_id: form.id,
          form_field_id: form_field.id,
          optional_override: false,
          config_override: %{attribute2: "val2"}
        })

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @form_fields_query,
          variables: %{
            formSlug: form.slug
          }
        })
        |> json_response(200)

      assert %{"data" => %{"formFieldsForCurrentUser" => form_fields}} = response
      assert hd(form_fields)["value"] == "http://foo.bar"
      assert hd(form_fields)["optional"] == false
    end

    test "it returns a country-specific form_field with a value for the given current user and form",
         %{conn: conn} do
      country = Factory.insert(:country)
      address = Factory.insert(:address, %{country_id: country.id})

      user =
        Factory.insert(:user, %{
          marital_status: "single",
          work_address_id: address.id
        })

      EmploymentHelpers.setup_employment(user, country)

      form = Factory.insert(:form)

      country_form_field =
        Factory.insert(:form_field, %{
          slug: "field2",
          optional: true,
          source_table: "users",
          source_table_field: "marital_status"
        })

      _country_form_form_field =
        Factory.insert(:form_form_field, %{
          form_id: form.id,
          form_field_id: country_form_field.id,
          country_id: country.id
        })

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @form_fields_query,
          variables: %{
            formSlug: form.slug
          }
        })
        |> json_response(200)

      assert %{"data" => %{"formFieldsForCurrentUser" => form_fields}} = response
      assert hd(form_fields)["country_id"] == Integer.to_string(country.id)
      assert hd(form_fields)["value"] == "single"
    end

    test "returns a field with a value from within a json column",
         %{conn: conn} do
      country = Factory.insert(:country)
      address = Factory.insert(:address, %{country_id: country.id})

      user =
        Factory.insert(:user, %{
          work_address_id: address.id,
          country_specific_fields: %{"field1" => "val1"}
        })

      EmploymentHelpers.setup_employment(user, country)

      form = Factory.insert(:form)

      country_form_field =
        Factory.insert(:form_field, %{
          slug: "field2",
          optional: true,
          source_table: "users",
          source_table_field: "country_specific_fields.field1"
        })

      _country_form_form_field =
        Factory.insert(:form_form_field, %{
          form_id: form.id,
          form_field_id: country_form_field.id,
          country_id: country.id
        })

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @form_fields_query,
          variables: %{
            formSlug: form.slug
          }
        })
        |> json_response(200)

      assert %{"data" => %{"formFieldsForCurrentUser" => form_fields}} = response
      assert hd(form_fields)["value"] == "val1"
    end

    test "it returns a form_field with overrides and a value for the given current user and form on a different table",
         %{conn: conn} do
      country = Factory.insert(:country)
      address = Factory.insert(:address, %{country_id: country.id})
      payment_address = Factory.insert(:address, %{country_id: country.id, line_1: "payment"})

      user =
        Factory.insert(:user, %{
          avatar_url: "http://foo.bar",
          work_address_id: address.id,
          country_specific_fields: %{
            payment_address_id: payment_address.id
          }
        })

      EmploymentHelpers.setup_employment(user, country)

      form = Factory.insert(:form)

      form_field =
        Factory.insert(:form_field, %{
          slug: "work-address-line-1",
          optional: true,
          source_table: "addresses",
          source_table_field: "line_1",
          config: %{foreign_key_path: "users.work_address_id"}
        })

      _form_form_field =
        Factory.insert(:form_form_field, %{
          form_id: form.id,
          form_field_id: form_field.id,
          optional_override: false
        })

      user_form_field =
        Factory.insert(:form_field, %{
          slug: "field1",
          optional: true,
          source_table: "users",
          source_table_field: "avatar_url"
        })

      user_form_field2 =
        Factory.insert(:form_field, %{
          slug: "field",
          optional: true,
          source_table: "users",
          source_table_field: "first_name",
          config: %{attribute1: "val1"}
        })

      _user_form_form_field =
        Factory.insert(:form_form_field, %{
          form_id: form.id,
          form_field_id: user_form_field2.id,
          optional_override: false
        })

      _user_form_form_field =
        Factory.insert(:form_form_field, %{
          form_id: form.id,
          form_field_id: user_form_field.id,
          optional_override: false,
          config_override: %{attribute2: "val2"}
        })

      csf_form_field =
        Factory.insert(:form_field, %{
          slug: "3",
          optional: true,
          source_table: "addresses",
          source_table_field: "line_1",
          config: %{foreign_key_path: "users.country_specific_fields.payment_address_id"}
        })

      _user_form_form_field =
        Factory.insert(:form_form_field, %{
          form_id: form.id,
          form_field_id: csf_form_field.id,
          optional_override: false
        })

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @form_fields_query,
          variables: %{
            formSlug: form.slug
          }
        })
        |> json_response(200)

      assert %{"data" => %{"formFieldsForCurrentUser" => form_fields}} = response

      assert Enum.find(form_fields, fn field ->
               Map.get(field, "value") == "payment"
             end)
    end

    test "it returns nil for a form field on a different table that has a nested foreign key",
         %{conn: conn} do
      country = Factory.insert(:country)
      address = Factory.insert(:address, %{country_id: country.id})

      user =
        Factory.insert(:user, %{
          avatar_url: "http://foo.bar",
          work_address_id: address.id
        })

      EmploymentHelpers.setup_employment(user, country)

      form = Factory.insert(:form)

      csf_form_field =
        Factory.insert(:form_field, %{
          slug: "3",
          optional: true,
          source_table: "addresses",
          source_table_field: "line_1",
          config: %{foreign_key_path: "users.country_specific_fields.field1.payment_address_id"}
        })

      _csf_form_form_field =
        Factory.insert(:form_form_field, %{
          form_id: form.id,
          form_field_id: csf_form_field.id,
          optional_override: false
        })

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @form_fields_query,
          variables: %{
            formSlug: form.slug
          }
        })
        |> json_response(200)

      assert %{"data" => %{"formFieldsForCurrentUser" => _form_fields}} = response
    end
  end

  @form_fields_for_user_query """
    query($formSlug: ID!, $userId: ID!) {
      formFieldsForUser(formSlug: $formSlug, userId: $userId) {
        id
        slug
        country_id
        optional
        config
        value
      }
    }
  """

  describe "query :form_fields_for_user" do
    test "it returns a form_field with values for a given user and form",
         %{conn: conn} do
      country = Factory.insert(:country)
      address = Factory.insert(:address, %{country_id: country.id})
      payment_address = Factory.insert(:address, %{country_id: country.id, line_1: "payment"})

      user1 =
        Factory.insert(:user, %{
          avatar_url: "http://foo.bar",
          work_address_id: address.id,
          country_specific_fields: %{
            payment_address_id: payment_address.id
          }
        })

      EmploymentHelpers.setup_employment(user1, country)

      # set up admin user
      admin_user = Factory.insert(:user)
      admin_group = Factory.insert(:group, %{slug: "admin", okta_group_slug: "PegaAdmins"})
      Factory.insert(:user_group, %{user_id: admin_user.id, group_id: admin_group.id})

      form = Factory.insert(:form)

      form_field =
        Factory.insert(:form_field, %{
          slug: "field1",
          optional: true,
          source_table: "users",
          source_table_field: "avatar_url",
          config: %{attribute1: "val1"}
        })

      _form_form_field =
        Factory.insert(:form_form_field, %{
          form_id: form.id,
          form_field_id: form_field.id,
          optional_override: false,
          config_override: %{attribute2: "val2"}
        })

      csf_form_field =
        Factory.insert(:form_field, %{
          slug: "3",
          optional: true,
          source_table: "addresses",
          source_table_field: "line_1",
          config: %{foreign_key_path: "users.country_specific_fields.payment_address_id"}
        })

      _csf_form_form_field =
        Factory.insert(:form_form_field, %{
          form_id: form.id,
          form_field_id: csf_form_field.id,
          optional_override: false
        })

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", admin_user.okta_user_uid)
        |> post("/graphql", %{
          query: @form_fields_for_user_query,
          variables: %{
            formSlug: form.slug,
            userId: user1.id
          }
        })
        |> json_response(200)

      assert %{"data" => %{"formFieldsForUser" => form_fields}} = response
      assert hd(form_fields)["value"] == "http://foo.bar"
      assert hd(form_fields)["optional"] == false
      assert List.last(form_fields)["value"] == "payment"
    end
  end

  @form_list_query """
    query($formSlugs: [ID]!) {
      formsBySlugForCurrentUser(formSlugs: $formSlugs) {
        id
        slug
        form_fields {
          id
          slug
          country_id
          optional
          config
          value
        }
      }
    }
  """

  describe "query :forms_by_slug_for_current_user" do
    test "it returns a list of forms with fields values for the given current user",
         %{conn: conn} do
      country = Factory.insert(:country)
      address = Factory.insert(:address, %{country_id: country.id})

      user =
        Factory.insert(:user, %{
          avatar_url: "http://foo.bar",
          work_address_id: address.id,
          marital_status: "single"
        })

      EmploymentHelpers.setup_employment(user, country)

      form =
        Factory.insert(:form, %{
          slug: "form-1"
        })

      second_form =
        Factory.insert(:form, %{
          slug: "form-2"
        })

      form_field =
        Factory.insert(:form_field, %{
          slug: "field1",
          optional: true,
          source_table: "users",
          source_table_field: "avatar_url",
          config: %{attribute1: "val1"}
        })

      second_form_field =
        Factory.insert(:form_field, %{
          slug: "field2",
          optional: true,
          source_table: "users",
          source_table_field: "marital_status",
          config: %{attribute1: "val2"}
        })

      _form_form_field =
        Factory.insert(:form_form_field, %{
          form_id: form.id,
          form_field_id: form_field.id
        })

      _second_form_form_field =
        Factory.insert(:form_form_field, %{
          form_id: second_form.id,
          form_field_id: second_form_field.id
        })

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @form_list_query,
          variables: %{
            formSlugs: ["form-1", "form-2"]
          }
        })
        |> json_response(200)

      assert %{"data" => %{"formsBySlugForCurrentUser" => forms_by_slug}} = response
      assert hd(forms_by_slug)["slug"] == "form-1"
    end
  end

  @form_list_for_user_query """
    query($formSlugs: [ID]!, $userId: [ID]!) {
      formsBySlugForUser(formSlugs: $formSlugs, userId: $userId) {
        id
        slug
        form_fields {
          id
          slug
          country_id
          optional
          config
          value
        }
      }
    }
  """

  describe "query :forms_by_slug_for_user" do
    test "it returns a list of forms with fields values for a passed in user",
         %{conn: conn} do
      country = Factory.insert(:country)
      address = Factory.insert(:address, %{country_id: country.id})

      user1 =
        Factory.insert(:user, %{
          avatar_url: "http://foo.bar",
          work_address_id: address.id,
          marital_status: "single"
        })

      EmploymentHelpers.setup_employment(user1, country)

      # set up admin user
      admin_user = Factory.insert(:user)
      admin_group = Factory.insert(:group, %{slug: "admin", okta_group_slug: "PegaAdmins"})
      Factory.insert(:user_group, %{user_id: admin_user.id, group_id: admin_group.id})

      form =
        Factory.insert(:form, %{
          slug: "form-1"
        })

      second_form =
        Factory.insert(:form, %{
          slug: "form-2"
        })

      form_field =
        Factory.insert(:form_field, %{
          slug: "field1",
          optional: true,
          source_table: "users",
          source_table_field: "avatar_url",
          config: %{attribute1: "val1"}
        })

      second_form_field =
        Factory.insert(:form_field, %{
          slug: "field2",
          optional: true,
          source_table: "users",
          source_table_field: "marital_status",
          config: %{attribute1: "val2"}
        })

      _form_form_field =
        Factory.insert(:form_form_field, %{
          form_id: form.id,
          form_field_id: form_field.id
        })

      _second_form_form_field =
        Factory.insert(:form_form_field, %{
          form_id: second_form.id,
          form_field_id: second_form_field.id
        })

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", admin_user.okta_user_uid)
        |> post("/graphql", %{
          query: @form_list_for_user_query,
          variables: %{
            formSlugs: ["form-1", "form-2"],
            userId: user1.id
          }
        })
        |> json_response(200)

      assert %{"data" => %{"formsBySlugForUser" => forms_by_slug}} = response
      assert hd(forms_by_slug)["slug"] == "form-1"
    end
  end

  @save_form_values_mutation """
    mutation SaveFormValues($fieldValues: [FormFieldValue]!) {
      saveFormValuesForCurrentUser(fieldValues: $fieldValues) {
        id
        value
      }
    }
  """
  describe "mutation :save_form_values" do
    test "saves form values under the correct source_table/column", %{conn: conn} do
      country = Factory.insert(:country)
      address = Factory.insert(:address, %{country_id: country.id})

      user =
        Factory.insert(:user, %{
          avatar_url: "http://old.url",
          work_address_id: address.id
        })

      EmploymentHelpers.setup_employment(user, country)

      form = Factory.insert(:form)

      form_field_type = "text"

      form_field =
        Factory.insert(:form_field, %{
          slug: "field1",
          optional: true,
          type: form_field_type,
          source_table: "users",
          source_table_field: "avatar_url",
          config: %{attribute1: "val1"}
        })

      form_form_field =
        Factory.insert(:form_form_field, %{
          form_id: form.id,
          form_field_id: form_field.id,
          optional_override: false,
          config_override: %{attribute2: "val2"}
        })

      new_avatar_url = "http://new.url"

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @save_form_values_mutation,
          variables: %{
            fieldValues: [
              %{
                id: form_form_field.id,
                slug: form_field.slug,
                value: new_avatar_url,
                dataType: form_field_type
              }
            ]
          }
        })
        |> json_response(200)

      assert %{"data" => %{"saveFormValuesForCurrentUser" => _updated_fields}} = response

      updated_user = Repo.get(User, user.id)
      assert updated_user.avatar_url == new_avatar_url
    end

    test "saves form values under the correct source_table/column in the correct type", %{
      conn: conn
    } do
      country = Factory.insert(:country)
      country2 = Factory.insert(:country)
      address = Factory.insert(:address, %{country_id: country.id})

      user =
        Factory.insert(:user, %{
          nationality_id: country.id,
          work_address_id: address.id
        })

      EmploymentHelpers.setup_employment(user, country)

      form = Factory.insert(:form)

      form_field_type = "id"

      form_field =
        Factory.insert(:form_field, %{
          slug: "field1",
          optional: true,
          type: "text",
          source_table: "users",
          source_table_field: "nationality_id",
          config: %{type_override: form_field_type}
        })

      form_form_field =
        Factory.insert(:form_form_field, %{
          form_id: form.id,
          form_field_id: form_field.id,
          optional_override: false,
          config_override: nil
        })

      new_nationality_id = country2.id

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @save_form_values_mutation,
          variables: %{
            fieldValues: [
              %{
                id: form_form_field.id,
                slug: form_field.slug,
                value: "#{new_nationality_id}",
                dataType: form_field_type
              }
            ]
          }
        })
        |> json_response(200)

      assert %{"data" => %{"saveFormValuesForCurrentUser" => _updated_fields}} = response

      updated_user = Repo.get(User, user.id)
      assert updated_user.nationality_id == new_nationality_id
    end

    test "saves a value to a key within a json column", %{conn: conn} do
      country = Factory.insert(:country)
      address = Factory.insert(:address, %{country_id: country.id})

      user =
        Factory.insert(:user, %{
          country_specific_fields: %{"field1" => "val1"},
          work_address_id: address.id
        })

      EmploymentHelpers.setup_employment(user, country)

      form = Factory.insert(:form)

      form_field_type = "text"

      form_field =
        Factory.insert(:form_field, %{
          slug: "field2",
          type: form_field_type,
          source_table: "users",
          source_table_field: "country_specific_fields.field2"
        })

      form_form_field =
        Factory.insert(:form_form_field, %{
          form_id: form.id,
          form_field_id: form_field.id,
          country_id: country.id
        })

      expected_new_val = "val2"

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @save_form_values_mutation,
          variables: %{
            fieldValues: [
              %{
                id: form_form_field.id,
                slug: form_field.slug,
                value: expected_new_val,
                dataType: form_field_type
              }
            ]
          }
        })
        |> json_response(200)

      assert %{"data" => %{"saveFormValuesForCurrentUser" => _updated_fields}} = response

      updated_user = Repo.get(User, user.id)

      assert %{"field1" => "val1", "field2" => actual_new_val} =
               updated_user.country_specific_fields

      assert actual_new_val == expected_new_val
    end

    test "saves a value to a nested key within a json column", %{conn: conn} do
      country = Factory.insert(:country)
      address = Factory.insert(:address, %{country_id: country.id})

      user =
        Factory.insert(:user, %{
          country_specific_fields: %{"field1" => %{"subfield1" => "subval1"}},
          work_address_id: address.id
        })

      EmploymentHelpers.setup_employment(user, country)

      form = Factory.insert(:form)

      form_field_type = "text"

      form_field =
        Factory.insert(:form_field, %{
          slug: "subfield2",
          type: form_field_type,
          source_table: "users",
          source_table_field: "country_specific_fields.field1.subfield2"
        })

      form_form_field =
        Factory.insert(:form_form_field, %{
          form_id: form.id,
          form_field_id: form_field.id,
          country_id: country.id
        })

      expected_new_val = "subval2"

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @save_form_values_mutation,
          variables: %{
            fieldValues: [
              %{
                id: form_form_field.id,
                slug: form_field.slug,
                value: expected_new_val,
                dataType: form_field_type
              }
            ]
          }
        })
        |> json_response(200)

      assert %{"data" => %{"saveFormValuesForCurrentUser" => _updated_fields}} = response

      updated_user = Repo.get(User, user.id)

      assert %{"field1" => %{"subfield1" => "subval1", "subfield2" => actual_new_val}} =
               updated_user.country_specific_fields

      assert actual_new_val == expected_new_val
    end

    test "it updates an existing row on another table when the row's reference exists", %{
      conn: conn
    } do
      country = Factory.insert(:country)
      address = Factory.insert(:address, %{country_id: country.id})

      form = Factory.insert(:form)

      user =
        Factory.insert(:user, %{
          avatar_url: "http://foo.bar",
          work_address_id: address.id
        })

      EmploymentHelpers.setup_employment(user, country)

      work_address_line_1_ff =
        Factory.insert(:form_field, %{
          slug: "work_address_line_1",
          optional: true,
          type: "text",
          source_table: "addresses",
          source_table_field: "line_1",
          config: %{foreign_key_path: "users.work_address_id"}
        })

      work_address_line_1_fff =
        Factory.insert(:form_form_field, %{
          form_id: form.id,
          form_field_id: work_address_line_1_ff.id,
          optional_override: false
        })

      new_address_line_1 = "123 go street"

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @save_form_values_mutation,
          variables: %{
            fieldValues: [
              %{
                id: work_address_line_1_fff.id,
                slug: work_address_line_1_ff.slug,
                value: new_address_line_1,
                dataType: "text"
              }
            ]
          }
        })
        |> json_response(200)

      assert %{"data" => %{"saveFormValuesForCurrentUser" => _updated_fields}} = response

      work_address = Repo.get(Address, address.id)
      assert work_address.line_1 == new_address_line_1
    end

    test "it updates an existing row on another table when the row's reference exists in jsonb",
         %{conn: conn} do
      country = Factory.insert(:country)
      address = Factory.insert(:address, %{country_id: country.id})
      payment_address = Factory.insert(:address, %{country_id: country.id, line_1: "payment"})

      form = Factory.insert(:form)

      user =
        Factory.insert(:user, %{
          avatar_url: "http://foo.bar",
          work_address_id: address.id,
          country_specific_fields: %{
            payment_address_id: payment_address.id
          }
        })

      EmploymentHelpers.setup_employment(user, country)

      payment_address_line_1_ff =
        Factory.insert(:form_field, %{
          slug: "payment_address_line_1",
          optional: true,
          type: "text",
          source_table: "addresses",
          source_table_field: "line_1",
          config: %{foreign_key_path: "users.country_specific_fields.payment_address_id"}
        })

      payment_address_line_1_fff =
        Factory.insert(:form_form_field, %{
          form_id: form.id,
          form_field_id: payment_address_line_1_ff.id,
          optional_override: false
        })

      new_address_line_1 = "123 go street"

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @save_form_values_mutation,
          variables: %{
            fieldValues: [
              %{
                id: payment_address_line_1_fff.id,
                slug: payment_address_line_1_ff.slug,
                value: new_address_line_1,
                dataType: "text"
              }
            ]
          }
        })
        |> json_response(200)

      assert %{"data" => %{"saveFormValuesForCurrentUser" => _updated_fields}} = response

      payment_address = Repo.get(Address, payment_address.id)
      assert payment_address.line_1 == new_address_line_1
    end

    test "it creates a new row on another table when the row's reference does not exist", %{
      conn: conn
    } do
      country = Factory.insert(:country)
      work_address = Factory.insert(:address, %{country_id: country.id})

      form = Factory.insert(:form)

      user =
        Factory.insert(:user, %{
          avatar_url: "http://foo.bar",
          work_address_id: work_address.id
        })

      EmploymentHelpers.setup_employment(user, country)

      personal_address_line_1_ff =
        Factory.insert(:form_field, %{
          slug: "personal_address_line_1",
          optional: true,
          type: "text",
          source_table: "addresses",
          source_table_field: "line_1",
          config: %{foreign_key_path: "users.personal_address_id"}
        })

      personal_address_line_1_fff =
        Factory.insert(:form_form_field, %{
          form_id: form.id,
          form_field_id: personal_address_line_1_ff.id,
          optional_override: false
        })

      new_address_line_1 = "123 go street"

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @save_form_values_mutation,
          variables: %{
            fieldValues: [
              %{
                id: personal_address_line_1_fff.id,
                slug: personal_address_line_1_ff.slug,
                value: new_address_line_1,
                dataType: "text"
              }
            ]
          }
        })
        |> json_response(200)

      assert %{"data" => %{"saveFormValuesForCurrentUser" => updated_fields}} = response
      assert Enum.at(updated_fields, 0)["value"] == new_address_line_1
    end

    test "it creates a new row on another table when the row's reference does not exist in jsonb",
         %{conn: conn} do
      country = Factory.insert(:country)
      address = Factory.insert(:address, %{country_id: country.id})

      form = Factory.insert(:form)

      user =
        Factory.insert(:user, %{
          avatar_url: "http://foo.bar",
          work_address_id: address.id
        })

      EmploymentHelpers.setup_employment(user, country)

      payment_address_line_1_ff =
        Factory.insert(:form_field, %{
          slug: "payment_address_line_1",
          optional: true,
          type: "text",
          source_table: "addresses",
          source_table_field: "line_1",
          config: %{foreign_key_path: "users.country_specific_fields.payment_address_id"}
        })

      payment_address_line_1_fff =
        Factory.insert(:form_form_field, %{
          form_id: form.id,
          form_field_id: payment_address_line_1_ff.id,
          optional_override: false
        })

      new_address_line_1 = "123 go street"

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @save_form_values_mutation,
          variables: %{
            fieldValues: [
              %{
                id: payment_address_line_1_fff.id,
                slug: payment_address_line_1_ff.slug,
                value: new_address_line_1,
                dataType: "text"
              }
            ]
          }
        })
        |> json_response(200)

      assert %{"data" => %{"saveFormValuesForCurrentUser" => updated_fields}} = response
      assert Enum.at(updated_fields, 0)["value"] == new_address_line_1
    end

    test "it creates a new row on another table when the row's reference does not exist in nested jsonb",
         %{conn: conn} do
      country = Factory.insert(:country)
      address = Factory.insert(:address, %{country_id: country.id})

      form = Factory.insert(:form)

      user =
        Factory.insert(:user, %{
          avatar_url: "http://foo.bar",
          work_address_id: address.id
        })

      EmploymentHelpers.setup_employment(user, country)

      payment_address_line_1_ff =
        Factory.insert(:form_field, %{
          slug: "payment_address_line_1",
          optional: true,
          type: "text",
          source_table: "addresses",
          source_table_field: "line_1",
          config: %{foreign_key_path: "users.country_specific_fields.field1.payment_address_id"}
        })

      payment_address_line_1_fff =
        Factory.insert(:form_form_field, %{
          form_id: form.id,
          form_field_id: payment_address_line_1_ff.id,
          optional_override: false
        })

      new_address_line_1 = "123 go street"

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @save_form_values_mutation,
          variables: %{
            fieldValues: [
              %{
                id: payment_address_line_1_fff.id,
                slug: payment_address_line_1_ff.slug,
                value: new_address_line_1,
                dataType: "text"
              }
            ]
          }
        })
        |> json_response(200)

      assert %{"data" => %{"saveFormValuesForCurrentUser" => updated_fields}} = response
      assert Enum.at(updated_fields, 0)["value"] == new_address_line_1
      updated_user = Repo.get(User, user.id)

      new_address =
        Address
        |> Repo.get_by(line_1: new_address_line_1)

      new_address_id = new_address.id

      assert %{"field1" => %{"payment_address_id" => ^new_address_id}} =
               updated_user.country_specific_fields
    end

    test "it updates and creates rows with a multitude of form field source tables where references exist and do not exist",
         %{conn: conn} do
      country = Factory.insert(:country)
      address = Factory.insert(:address, %{country_id: country.id})

      user =
        Factory.insert(:user, %{
          avatar_url: "http://foo.bar",
          work_address_id: address.id
        })

      EmploymentHelpers.setup_employment(user, country)

      _form_field_type = "text"
      form = Factory.insert(:form)

      # insert counrty specific address line 1 form field
      payment_address_line_1_ff =
        Factory.insert(:form_field, %{
          slug: "payment_address_line_1",
          optional: true,
          type: "text",
          source_table: "addresses",
          source_table_field: "line_1",
          config: %{foreign_key_path: "users.country_specific_fields.payment_address_id"}
        })

      payment_address_line_1_fff =
        Factory.insert(:form_form_field, %{
          form_id: form.id,
          form_field_id: payment_address_line_1_ff.id,
          optional_override: false
        })

      # insert counrty specific address line 2 form field
      payment_address_line_2_ff =
        Factory.insert(:form_field, %{
          slug: "payment_address_line_2",
          optional: true,
          type: "text",
          source_table: "addresses",
          source_table_field: "line_2",
          config: %{foreign_key_path: "users.country_specific_fields.payment_address_id"}
        })

      payment_address_line_2_fff =
        Factory.insert(:form_form_field, %{
          form_id: form.id,
          form_field_id: payment_address_line_2_ff.id,
          optional_override: false
        })

      # insert user first name form field
      user_first_name_ff =
        Factory.insert(:form_field, %{
          slug: "user_first_name",
          optional: true,
          source_table: "users",
          source_table_field: "first_name"
        })

      user_first_name_fff =
        Factory.insert(:form_form_field, %{
          form_id: form.id,
          form_field_id: user_first_name_ff.id
        })

      # insert user personal address id line_1 form field
      personal_address_line_1_ff =
        Factory.insert(:form_field, %{
          slug: "personal_address_line_1",
          optional: true,
          type: "text",
          source_table: "addresses",
          source_table_field: "line_1",
          config: %{foreign_key_path: "users.personal_address_id"}
        })

      personal_address_line_1_fff =
        Factory.insert(:form_form_field, %{
          form_id: form.id,
          form_field_id: personal_address_line_1_ff.id,
          optional_override: false
        })

      # insert user work address id line_1 form field
      work_address_line_1_ff =
        Factory.insert(:form_field, %{
          slug: "work_address_id_line_1",
          optional: true,
          type: "text",
          source_table: "addresses",
          source_table_field: "line_1",
          config: %{foreign_key_path: "users.work_address_id"}
        })

      work_address_line_1_fff =
        Factory.insert(:form_form_field, %{
          form_id: form.id,
          form_field_id: work_address_line_1_ff.id,
          optional_override: false
        })

      payment_address_new_line_1 = "Payment Address Line 1"
      payment_address_new_line_2 = "Payment Address Line 2"
      new_first_name = "First Name"
      personal_address_new_line_1 = "Personal Address Line 1"
      work_address_updated_line_1 = "Work Address Line 1"

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", user.okta_user_uid)
        |> post("/graphql", %{
          query: @save_form_values_mutation,
          variables: %{
            fieldValues: [
              %{
                id: payment_address_line_1_fff.id,
                slug: payment_address_line_1_ff.slug,
                value: payment_address_new_line_1,
                dataType: "text"
              },
              %{
                id: payment_address_line_2_fff.id,
                slug: payment_address_line_2_ff.slug,
                value: payment_address_new_line_2,
                dataType: "text"
              },
              %{
                id: user_first_name_fff.id,
                slug: user_first_name_ff.slug,
                value: new_first_name,
                dataType: "text"
              },
              %{
                id: personal_address_line_1_fff.id,
                slug: personal_address_line_1_ff.slug,
                value: personal_address_new_line_1,
                dataType: "text"
              },
              %{
                id: work_address_line_1_fff.id,
                slug: work_address_line_1_ff.slug,
                value: work_address_updated_line_1,
                dataType: "text"
              }
            ]
          }
        })
        |> json_response(200)

      assert %{"data" => %{"saveFormValuesForCurrentUser" => updated_fields}} = response
      assert Enum.at(updated_fields, 0)["value"] == payment_address_new_line_1
      assert Enum.at(updated_fields, 1)["value"] == payment_address_new_line_2
      assert Enum.at(updated_fields, 2)["value"] == new_first_name
      assert Enum.at(updated_fields, 3)["value"] == personal_address_new_line_1
      assert Enum.at(updated_fields, 4)["value"] == work_address_updated_line_1
    end
  end

  @save_form_values_for_user_mutation """
    mutation SaveFormValues($fieldValues: [FormFieldValue]!, $userId: [ID]!) {
      saveFormValuesForUser(fieldValues: $fieldValues, userId: $userId) {
        id
        value
      }
    }
  """
  describe "mutation :save_form_values_for_user" do
    test "it updates and creates rows with a multitude of form field source tables where references exist and do not exist for a passed in user",
         %{conn: conn} do
      country = Factory.insert(:country)
      address = Factory.insert(:address, %{country_id: country.id})

      user1 =
        Factory.insert(:user, %{
          avatar_url: "http://foo.bar",
          work_address_id: address.id
        })

      EmploymentHelpers.setup_employment(user1, country)

      # set up admin user
      admin_user = Factory.insert(:user)
      admin_group = Factory.insert(:group, %{slug: "csr", okta_group_slug: "PegaAdmins"})
      Factory.insert(:user_group, %{user_id: admin_user.id, group_id: admin_group.id})

      _form_field_type = "text"
      form = Factory.insert(:form)

      # insert counrty specific address line 1 form field
      payment_address_line_1_ff =
        Factory.insert(:form_field, %{
          slug: "payment_address_line_1",
          optional: true,
          type: "text",
          source_table: "addresses",
          source_table_field: "line_1",
          config: %{foreign_key_path: "users.country_specific_fields.payment_address_id"}
        })

      payment_address_line_1_fff =
        Factory.insert(:form_form_field, %{
          form_id: form.id,
          form_field_id: payment_address_line_1_ff.id,
          optional_override: false
        })

      # insert counrty specific address line 2 form field
      payment_address_line_2_ff =
        Factory.insert(:form_field, %{
          slug: "payment_address_line_2",
          optional: true,
          type: "text",
          source_table: "addresses",
          source_table_field: "line_2",
          config: %{foreign_key_path: "users.country_specific_fields.payment_address_id"}
        })

      payment_address_line_2_fff =
        Factory.insert(:form_form_field, %{
          form_id: form.id,
          form_field_id: payment_address_line_2_ff.id,
          optional_override: false
        })

      # insert user first name form field
      user_first_name_ff =
        Factory.insert(:form_field, %{
          slug: "user_first_name",
          optional: true,
          source_table: "users",
          source_table_field: "first_name"
        })

      user_first_name_fff =
        Factory.insert(:form_form_field, %{
          form_id: form.id,
          form_field_id: user_first_name_ff.id
        })

      # insert user personal address id line_1 form field
      personal_address_line_1_ff =
        Factory.insert(:form_field, %{
          slug: "personal_address_line_1",
          optional: true,
          type: "text",
          source_table: "addresses",
          source_table_field: "line_1",
          config: %{foreign_key_path: "users.personal_address_id"}
        })

      personal_address_line_1_fff =
        Factory.insert(:form_form_field, %{
          form_id: form.id,
          form_field_id: personal_address_line_1_ff.id,
          optional_override: false
        })

      # insert user work address id line_1 form field
      work_address_line_1_ff =
        Factory.insert(:form_field, %{
          slug: "work_address_id_line_1",
          optional: true,
          type: "text",
          source_table: "addresses",
          source_table_field: "line_1",
          config: %{foreign_key_path: "users.work_address_id"}
        })

      work_address_line_1_fff =
        Factory.insert(:form_form_field, %{
          form_id: form.id,
          form_field_id: work_address_line_1_ff.id,
          optional_override: false
        })

      payment_address_new_line_1 = "Payment Address Line 1"
      payment_address_new_line_2 = "Payment Address Line 2"
      new_first_name = "First Name"
      personal_address_new_line_1 = "Personal Address Line 1"
      work_address_updated_line_1 = "Work Address Line 1"

      response =
        conn
        |> put_req_header("test-only-okta-user-uid", admin_user.okta_user_uid)
        |> post("/graphql", %{
          query: @save_form_values_for_user_mutation,
          variables: %{
            fieldValues: [
              %{
                id: payment_address_line_1_fff.id,
                slug: payment_address_line_1_ff.slug,
                value: payment_address_new_line_1,
                dataType: "text"
              },
              %{
                id: payment_address_line_2_fff.id,
                slug: payment_address_line_2_ff.slug,
                value: payment_address_new_line_2,
                dataType: "text"
              },
              %{
                id: user_first_name_fff.id,
                slug: user_first_name_ff.slug,
                value: new_first_name,
                dataType: "text"
              },
              %{
                id: personal_address_line_1_fff.id,
                slug: personal_address_line_1_ff.slug,
                value: personal_address_new_line_1,
                dataType: "text"
              },
              %{
                id: work_address_line_1_fff.id,
                slug: work_address_line_1_ff.slug,
                value: work_address_updated_line_1,
                dataType: "text"
              }
            ],
            userId: user1.id
          }
        })
        |> json_response(200)

      assert %{"data" => %{"saveFormValuesForUser" => updated_fields}} = response
      assert Enum.at(updated_fields, 0)["value"] == payment_address_new_line_1
      assert Enum.at(updated_fields, 1)["value"] == payment_address_new_line_2
      assert Enum.at(updated_fields, 3)["value"] == personal_address_new_line_1
      assert Enum.at(updated_fields, 4)["value"] == work_address_updated_line_1
      updated_user = Repo.get(User, user1.id)
      assert updated_user.first_name == new_first_name
      assert updated_user.avatar_url == "http://foo.bar"
    end
  end
end
