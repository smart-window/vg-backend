defmodule Velocity.Seeds.FormSeeds do
  import Ecto.Query
  alias Velocity.Repo
  alias Velocity.Schema.Country
  alias Velocity.Schema.Form
  alias Velocity.Schema.FormField
  alias Velocity.Schema.FormFormField

  # credo:disable-for-this-file Credo.Check.Refactor.CyclomaticComplexity

  @doc """
    Creates all forms, form_fields, and form_form_fields for the app.

    Countries should already be populated from Velocity.Seeds.CountryAndRegionSeeds
  """
  def create do
    countries = Repo.all(Country)
    inserted_and_updated_at = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    forms_map = [
      %{slug: "eeww-basic-info"},
      %{slug: "eeww-personal-info"},
      %{slug: "eeww-contact-info"},
      %{slug: "eeww-bank-info"},
      %{slug: "eeww-work-info"},
      %{slug: "eeww-identification-info"},
      %{slug: "eeww-other-info"},
      %{slug: "eeprofile-personal-info"},
      %{slug: "eeprofile-contact-info"},
      %{slug: "eeprofile-work-info"}
    ]

    forms_params =
      Enum.map(forms_map, fn form_item ->
        %{
          slug: form_item.slug,
          inserted_at: inserted_and_updated_at,
          updated_at: inserted_and_updated_at
        }
      end)

    {_num, forms} =
      Repo.insert_all(Form, forms_params,
        on_conflict: [set: [updated_at: inserted_and_updated_at]],
        conflict_target: :slug,
        returning: true
      )

    eeww_basic_info_form = Enum.find(forms, &(&1.slug == "eeww-basic-info"))
    eeww_personal_info_form = Enum.find(forms, &(&1.slug == "eeww-personal-info"))
    _eeww_contact_info_form = Enum.find(forms, &(&1.slug == "eeww-contact-info"))
    eeww_bank_info_form = Enum.find(forms, &(&1.slug == "eeww-bank-info"))
    eeww_work_info_form = Enum.find(forms, &(&1.slug == "eeww-work-info"))
    eeww_identification_info_form = Enum.find(forms, &(&1.slug == "eeww-identification-info"))
    eeww_other_info_form = Enum.find(forms, &(&1.slug == "eeww-other-info"))
    eeprofile_personal_info_form = Enum.find(forms, &(&1.slug == "eeprofile-personal-info"))
    eeprofile_contact_info_form = Enum.find(forms, &(&1.slug == "eeprofile-contact-info"))
    eeprofile_work_info_form = Enum.find(forms, &(&1.slug == "eeprofile-work-info"))

    eeww_basic_info_fields_map = [
      %{
        slug: "legal-first-name",
        type: :text,
        optional: false,
        source_table: "users",
        source_table_field: "first_name",
        config: %{},
        form_ids: [eeww_basic_info_form.id, eeprofile_personal_info_form.id]
      },
      %{
        slug: "legal-last-name",
        type: :text,
        optional: false,
        source_table: "users",
        source_table_field: "last_name",
        config: %{},
        form_ids: [eeww_basic_info_form.id, eeprofile_personal_info_form.id]
      },
      %{
        slug: "full-name",
        type: :text,
        optional: false,
        source_table: "users",
        source_table_field: "full_name",
        config: %{hiddden: true},
        form_ids: [eeww_basic_info_form.id, eeprofile_personal_info_form.id]
      },
      %{
        slug: "preferred-first-name",
        type: :text,
        optional: true,
        source_table: "users",
        source_table_field: "preferred_first_name",
        config: %{},
        form_ids: [eeww_basic_info_form.id, eeprofile_personal_info_form.id]
      },
      %{
        slug: "nationality",
        type: :select,
        optional: false,
        source_table: "users",
        source_table_field: "nationality_id",
        config: %{
          type_override: "id"
        },
        form_ids: [eeww_basic_info_form.id, eeprofile_personal_info_form.id]
      },
      %{
        slug: "date-of-birth",
        type: :date,
        optional: false,
        source_table: "users",
        source_table_field: "birth_date",
        config: %{},
        form_ids: [eeww_basic_info_form.id, eeprofile_personal_info_form.id]
      },
      %{
        slug: "gender",
        type: :select,
        optional: false,
        source_table: "users",
        source_table_field: "gender",
        config: %{},
        form_ids: [eeww_basic_info_form.id, eeprofile_personal_info_form.id]
      },
      %{
        slug: "marital-status",
        type: :select,
        optional: false,
        source_table: "users",
        source_table_field: "marital_status",
        config: %{},
        form_ids: [eeww_basic_info_form.id, eeprofile_personal_info_form.id]
      },
      %{
        slug: "primary-phone",
        type: :phone,
        optional: false,
        source_table: "users",
        source_table_field: "phone",
        config: %{},
        form_ids: [eeww_basic_info_form.id, eeprofile_contact_info_form.id]
      },
      %{
        slug: "business-email",
        type: :text,
        optional: false,
        source_table: "users",
        source_table_field: "business_email",
        config: %{},
        form_ids: [eeww_basic_info_form.id, eeprofile_contact_info_form.id]
      },
      %{
        slug: "personal-email",
        type: :text,
        optional: true,
        source_table: "users",
        source_table_field: "personal_email",
        config: %{},
        form_ids: [eeww_basic_info_form.id, eeprofile_contact_info_form.id]
      },
      %{
        slug: "work-address-line-1",
        type: :address,
        optional: false,
        source_table: "addresses",
        source_table_field: "line_1",
        config: %{
          foreign_key_path: "users.work_address_id",
          label: "Work Address"
        },
        form_ids: [eeww_basic_info_form.id, eeprofile_work_info_form.id]
      },
      %{
        slug: "work-address-line-2",
        type: :address,
        optional: true,
        source_table: "addresses",
        source_table_field: "line_2",
        config: %{
          foreign_key_path: "users.work_address_id",
          label: "Work Address"
        },
        form_ids: [eeww_basic_info_form.id, eeprofile_work_info_form.id]
      },
      %{
        slug: "work-address-line-3",
        type: :address,
        optional: true,
        source_table: "addresses",
        source_table_field: "line_3",
        config: %{
          foreign_key_path: "users.work_address_id",
          label: "Work Address"
        },
        form_ids: [eeww_basic_info_form.id, eeprofile_work_info_form.id]
      },
      %{
        slug: "work-address-city",
        type: :address,
        optional: false,
        source_table: "addresses",
        source_table_field: "city",
        config: %{
          foreign_key_path: "users.work_address_id",
          label: "Work Address"
        },
        form_ids: [eeww_basic_info_form.id, eeprofile_work_info_form.id]
      },
      %{
        slug: "work-address-postal-code",
        type: :address,
        optional: false,
        source_table: "addresses",
        source_table_field: "postal_code",
        config: %{
          foreign_key_path: "users.work_address_id",
          label: "Work Address"
        },
        form_ids: [eeww_basic_info_form.id, eeprofile_work_info_form.id]
      },
      %{
        slug: "work-address-county-district",
        type: :address,
        optional: true,
        source_table: "addresses",
        source_table_field: "county_district",
        config: %{
          foreign_key_path: "users.work_address_id",
          label: "Work Address"
        },
        form_ids: [eeww_basic_info_form.id, eeprofile_work_info_form.id]
      },
      %{
        slug: "work-address-state-province",
        type: :address,
        source_table: "addresses",
        optional: false,
        source_table_field: "state_province",
        config: %{
          foreign_key_path: "users.work_address_id",
          label: "Work Address"
        },
        form_ids: [eeww_basic_info_form.id, eeprofile_work_info_form.id]
      },
      %{
        slug: "work-address-state-province-iso-alpha-2-code",
        type: :address,
        source_table: "addresses",
        optional: false,
        source_table_field: "state_province_iso_alpha_2_code",
        config: %{
          foreign_key_path: "users.work_address_id",
          label: "Work Address"
        },
        form_ids: [eeww_basic_info_form.id, eeprofile_work_info_form.id]
      },
      %{
        slug: "work-address-country-id",
        type: :address,
        source_table: "addresses",
        optional: false,
        source_table_field: "country_id",
        config: %{
          foreign_key_path: "users.work_address_id",
          label: "Work Address",
          type_override: "id"
        },
        form_ids: [eeww_basic_info_form.id, eeprofile_work_info_form.id]
      },
      %{
        slug: "work-address-formatted-address",
        type: :address,
        source_table: "addresses",
        optional: false,
        source_table_field: "formatted_address",
        config: %{
          foreign_key_path: "users.work_address_id",
          label: "Work Address"
        },
        form_ids: [eeww_basic_info_form.id, eeprofile_work_info_form.id]
      },
      %{
        slug: "personal-address-line-1",
        type: :address,
        optional: false,
        source_table: "addresses",
        source_table_field: "line_1",
        config: %{
          foreign_key_path: "users.personal_address_id",
          label: "Personal Address"
        },
        form_ids: [eeww_basic_info_form.id, eeprofile_contact_info_form.id]
      },
      %{
        slug: "personal-address-line-2",
        type: :address,
        optional: true,
        source_table: "addresses",
        source_table_field: "line_2",
        config: %{
          foreign_key_path: "users.personal_address_id",
          label: "Personal Address"
        },
        form_ids: [eeww_basic_info_form.id, eeprofile_contact_info_form.id]
      },
      %{
        slug: "personal-address-line-3",
        type: :address,
        optional: true,
        source_table: "addresses",
        source_table_field: "line_3",
        config: %{
          foreign_key_path: "users.personal_address_id",
          label: "Personal Address"
        },
        form_ids: [eeww_basic_info_form.id, eeprofile_contact_info_form.id]
      },
      %{
        slug: "personal-address-city",
        type: :address,
        optional: false,
        source_table: "addresses",
        source_table_field: "city",
        config: %{
          foreign_key_path: "users.personal_address_id",
          label: "Personal Address"
        },
        form_ids: [eeww_basic_info_form.id, eeprofile_contact_info_form.id]
      },
      %{
        slug: "personal-address-postal-code",
        type: :address,
        optional: false,
        source_table: "addresses",
        source_table_field: "postal_code",
        config: %{
          foreign_key_path: "users.personal_address_id",
          label: "Personal Address"
        },
        form_ids: [eeww_basic_info_form.id, eeprofile_contact_info_form.id]
      },
      %{
        slug: "personal-address-county-district",
        type: :address,
        optional: true,
        source_table: "addresses",
        source_table_field: "county_district",
        config: %{
          foreign_key_path: "users.personal_address_id",
          label: "Personal Address"
        },
        form_ids: [eeww_basic_info_form.id, eeprofile_contact_info_form.id]
      },
      %{
        slug: "personal-address-state-province",
        type: :address,
        source_table: "addresses",
        optional: false,
        source_table_field: "state_province",
        config: %{
          foreign_key_path: "users.personal_address_id",
          label: "Personal Address"
        },
        form_ids: [eeww_basic_info_form.id, eeprofile_contact_info_form.id]
      },
      %{
        slug: "personal-address-state-province-iso-alpha-2-code",
        type: :address,
        source_table: "addresses",
        optional: false,
        source_table_field: "state_province_iso_alpha_2_code",
        config: %{
          foreign_key_path: "users.personal_address_id",
          label: "Personal Address"
        },
        form_ids: [eeww_basic_info_form.id, eeprofile_contact_info_form.id]
      },
      %{
        slug: "personal-address-country-id",
        type: :address,
        source_table: "addresses",
        optional: false,
        source_table_field: "country_id",
        config: %{
          foreign_key_path: "users.personal_address_id",
          label: "Personal Address",
          type_override: "id"
        },
        form_ids: [eeww_basic_info_form.id, eeprofile_contact_info_form.id]
      },
      %{
        slug: "personal-address-formatted-address",
        type: :address,
        source_table: "addresses",
        optional: false,
        source_table_field: "formatted_address",
        config: %{
          foreign_key_path: "users.personal_address_id",
          label: "Personal Address"
        },
        form_ids: [eeww_basic_info_form.id, eeprofile_contact_info_form.id]
      },
      %{
        slug: "emergency-contact-name",
        type: :text,
        optional: false,
        source_table: "users",
        source_table_field: "emergency_contact_name",
        config: %{},
        form_ids: [eeww_basic_info_form.id, eeprofile_personal_info_form.id]
      },
      %{
        slug: "emergency-contact-relationship",
        type: :select,
        optional: false,
        source_table: "users",
        source_table_field: "emergency_contact_relationship",
        config: %{},
        form_ids: [eeww_basic_info_form.id, eeprofile_personal_info_form.id]
      },
      %{
        slug: "emergency-contact-phone",
        type: :phone,
        optional: false,
        source_table: "users",
        source_table_field: "emergency_contact_phone",
        config: %{},
        form_ids: [eeww_basic_info_form.id, eeprofile_personal_info_form.id]
      }
    ]

    # Global fields outside of eeww-basic-info
    other_global_fields_map = [
      %{
        slug: "bank-account-holder-name",
        type: :text,
        optional: false,
        source_table: "users",
        source_table_field: "bank_account_holder_name",
        config: %{
          label: "Bank Account Holder Name"
        },
        country_id: nil,
        form_ids: [eeww_bank_info_form.id]
      },
      %{
        slug: "bank-name",
        type: :text,
        optional: false,
        source_table: "users",
        source_table_field: "bank_name",
        config: %{
          label: "Bank Name"
        },
        country_id: nil,
        form_ids: [eeww_bank_info_form.id]
      },
      %{
        slug: "bank-account-number",
        type: :number,
        optional: true,
        source_table: "users",
        source_table_field: "bank_account_number",
        config: %{
          label: "Bank Account Number"
        },
        country_id: nil,
        form_ids: [eeww_bank_info_form.id]
      },
      %{
        slug: "bank-account-type",
        type: :text,
        optional: true,
        source_table: "users",
        source_table_field: "bank_account_type",
        config: %{
          label: "Account Type"
        },
        country_id: nil,
        form_ids: [eeww_bank_info_form.id]
      },
      %{
        slug: "bank-address-line-1",
        type: :address,
        optional: false,
        source_table: "addresses",
        source_table_field: "line_1",
        config: %{
          foreign_key_path: "users.bank_address_id",
          label: "Bank Address"
        },
        country_id: nil,
        form_ids: [eeww_bank_info_form.id]
      },
      %{
        slug: "bank-address-line-2",
        type: :address,
        optional: true,
        source_table: "addresses",
        source_table_field: "line_2",
        config: %{
          foreign_key_path: "users.bank_address_id",
          label: "Bank Address"
        },
        country_id: nil,
        form_ids: [eeww_bank_info_form.id]
      },
      %{
        slug: "bank-address-line-3",
        type: :address,
        optional: true,
        source_table: "addresses",
        source_table_field: "line_3",
        config: %{
          foreign_key_path: "users.bank_address_id",
          label: "Bank Address"
        },
        country_id: nil,
        form_ids: [eeww_bank_info_form.id]
      },
      %{
        slug: "bank-address-city",
        type: :address,
        optional: false,
        source_table: "addresses",
        source_table_field: "city",
        config: %{
          foreign_key_path: "users.bank_address_id",
          label: "Bank Address"
        },
        country_id: nil,
        form_ids: [eeww_bank_info_form.id]
      },
      %{
        slug: "bank-address-postal-code",
        type: :address,
        optional: false,
        source_table: "addresses",
        source_table_field: "postal_code",
        config: %{
          foreign_key_path: "users.bank_address_id",
          label: "Bank Address"
        },
        country_id: nil,
        form_ids: [eeww_bank_info_form.id]
      },
      %{
        slug: "bank-address-county-district",
        type: :address,
        optional: true,
        source_table: "addresses",
        source_table_field: "county_district",
        config: %{
          foreign_key_path: "users.bank_address_id",
          label: "Bank Address"
        },
        country_id: nil,
        form_ids: [eeww_bank_info_form.id]
      },
      %{
        slug: "bank-address-state-province",
        type: :address,
        source_table: "addresses",
        optional: false,
        source_table_field: "state_province",
        config: %{
          foreign_key_path: "users.bank_address_id",
          label: "Bank Address"
        },
        country_id: nil,
        form_ids: [eeww_bank_info_form.id]
      },
      %{
        slug: "bank-address-state-province-iso-alpha-2-code",
        type: :address,
        source_table: "addresses",
        optional: false,
        source_table_field: "state_province_iso_alpha_2_code",
        config: %{
          foreign_key_path: "users.bank_address_id",
          label: "Bank Address"
        },
        country_id: nil,
        form_ids: [eeww_bank_info_form.id]
      },
      %{
        slug: "bank-address-country-id",
        type: :address,
        source_table: "addresses",
        optional: false,
        source_table_field: "country_id",
        config: %{
          foreign_key_path: "users.bank_address_id",
          label: "Bank Address",
          type_override: "id"
        },
        country_id: nil,
        form_ids: [eeww_bank_info_form.id]
      },
      %{
        slug: "bank-address-formatted-address",
        type: :address,
        source_table: "addresses",
        optional: false,
        source_table_field: "formatted_address",
        config: %{
          foreign_key_path: "users.bank_address_id",
          label: "Bank Address"
        },
        form_ids: [eeww_bank_info_form.id]
      }

      # %{
      #   slug: "country-of-employment",
      #   type: :select,
      #   optional: true,
      #   source_table: "users",
      #   source_table_field: "country_of_employment_id",
      #   config: %{
      #     label: "Country of Employment",
      #     options: []
      #   },
      #   country_id: nil,
      #   form_id: [eeww_work_info_form.id, eeprofile_work_info_form.id]
      # }
    ]

    merged_global_eeww_field_data = eeww_basic_info_fields_map ++ other_global_fields_map

    eeww_global_field_params =
      Enum.map(merged_global_eeww_field_data, fn form_field ->
        %{
          slug: form_field.slug,
          type: form_field.type,
          optional: form_field.optional,
          source_table: form_field.source_table,
          source_table_field: form_field.source_table_field,
          config: form_field.config || %{},
          inserted_at: inserted_and_updated_at,
          updated_at: inserted_and_updated_at
        }
      end)

    {_num, form_fields} =
      Repo.insert_all(FormField, eeww_global_field_params,
        on_conflict: {:replace_all_except, [:slug, :id, :inserted_at]},
        conflict_target: :slug,
        returning: true
      )

    # No country overrides on this form
    eeww_global_form_form_field_params =
      Enum.reduce(form_fields, [], fn form_field, acc ->
        form_field_data =
          Enum.find(merged_global_eeww_field_data, fn field_data ->
            field_data.slug == form_field.slug
          end)

        form_field_by_forms_param =
          Enum.map(form_field_data.form_ids, fn form_id ->
            %{
              form_id: form_id,
              form_field_id: form_field.id,
              inserted_at: inserted_and_updated_at,
              updated_at: inserted_and_updated_at
            }
          end)

        acc ++ form_field_by_forms_param
      end)

    # Can't insert_all because country_id (part of unique index) may be nil
    Enum.each(eeww_global_form_form_field_params, fn form_field_params ->
      existing_form_form_field =
        Repo.one(
          from f in FormFormField,
            where:
              f.form_id == ^form_field_params.form_id and
                f.form_field_id == ^form_field_params.form_field_id
        )

      if is_nil(existing_form_form_field) do
        changeset = FormFormField.changeset(%FormFormField{}, form_field_params)
        Repo.insert!(changeset)
      else
        changeset =
          FormFormField.changeset(existing_form_form_field, %{
            inserted_at: form_field_params.inserted_at,
            updated_at: form_field_params.updated_at
          })

        Repo.update!(changeset)
      end
    end)

    # Country-specific forms/fields
    australia = Enum.find(countries, &(&1.iso_alpha_2_code == "AU"))
    brazil = Enum.find(countries, &(&1.iso_alpha_2_code == "BR"))
    canada = Enum.find(countries, &(&1.iso_alpha_2_code == "CA"))
    colombia = Enum.find(countries, &(&1.iso_alpha_2_code == "CO"))
    france = Enum.find(countries, &(&1.iso_alpha_2_code == "FR"))
    united_kingdom = Enum.find(countries, &(&1.iso_alpha_2_code == "GB"))
    hong_kong = Enum.find(countries, &(&1.iso_alpha_2_code == "HK"))
    india = Enum.find(countries, &(&1.iso_alpha_2_code == "IN"))
    italy = Enum.find(countries, &(&1.iso_alpha_2_code == "IT"))
    mexico = Enum.find(countries, &(&1.iso_alpha_2_code == "MX"))
    netherlands = Enum.find(countries, &(&1.iso_alpha_2_code == "NL"))
    new_zealand = Enum.find(countries, &(&1.iso_alpha_2_code == "NZ"))
    singapore = Enum.find(countries, &(&1.iso_alpha_2_code == "SG"))
    spain = Enum.find(countries, &(&1.iso_alpha_2_code == "ES"))
    south_korea = Enum.find(countries, &(&1.iso_alpha_2_code == "KR"))
    uae = Enum.find(countries, &(&1.iso_alpha_2_code == "AE"))

    country_specific_fields_map = [
      #
      # Overlapping (fields that multiple countries have)
      #
      %{
        slug: "social-security-number",
        type: :private,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.social_security_number",
        config: %{
          base: %{label: "Social Security Number"},
          ES: %{order: 1},
          BR: %{label: "C.T.P.S. Nº", order: 4},
          FR: %{label: "n de securite sociale de l'assure", order: 7},
          MX: %{order: 8},
          NL: %{label: "BSN", order: 1}
        },
        country: [mexico, netherlands, spain, brazil, france],
        form_id: eeww_identification_info_form.id
      },
      %{
        slug: "iban",
        type: :number,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.iban",
        config: %{
          base: %{label: "IBAN", order: 1}
        },
        country: [netherlands, spain, france],
        form_id: eeww_bank_info_form.id
      },
      %{
        slug: "bsb",
        type: :number,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.bsb",
        config: %{
          base: %{label: "BSB"},
          AU: %{order: 2},
          NZ: %{label: "Bank Branch/BSB", order: 1}
        },
        country: [australia, new_zealand],
        form_id: eeww_bank_info_form.id
      },
      %{
        slug: "swift-code",
        type: :number,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.swift_code",
        config: %{
          base: %{label: "SWIFT/BIC Code"},
          NL: %{order: 2},
          FR: %{order: 2},
          KR: %{label: "Swift/BIC Code", order: 2},
          ES: %{label: "Swift Code", order: 2}
        },
        country: [netherlands, spain, south_korea, france],
        form_id: eeww_bank_info_form.id
      },
      %{
        slug: "bank-branch",
        type: :text,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.bank_branch",
        config: %{
          base: %{label: "Bank Branch", order: 1}
        },
        country: [australia, singapore, south_korea],
        form_id: eeww_bank_info_form.id
      },
      %{
        slug: "bank-code",
        type: :number,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.bank_code",
        config: %{
          base: %{label: "Bank Code"},
          SG: %{order: 3},
          HK: %{order: 1}
        },
        country: [singapore, hong_kong],
        form_id: eeww_bank_info_form.id
      },
      %{
        slug: "branch-code",
        type: :number,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.branch_code",
        config: %{
          base: %{label: "Branch Code"},
          CA: %{label: "Branch Number", order: 2},
          HK: %{order: 2},
          IN: %{order: 1},
          SG: %{order: 2}
        },
        country: [india, singapore, hong_kong, canada],
        form_id: eeww_bank_info_form.id
      },
      %{
        slug: "national-id-number",
        type: :private,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.national_id_number",
        config: %{
          base: %{label: "National ID Number"},
          AU: %{order: 5},
          CO: %{order: 1},
          MX: %{label: "National ID", order: 5},
          NZ: %{order: 1},
          ES: %{order: 2}
        },
        country: [australia, colombia, mexico, new_zealand, spain],
        form_id: eeww_identification_info_form.id
      },
      %{
        slug: "passport-number",
        type: :text,
        optional: true,
        source_table: "users",
        source_table_field: "country_specific_fields.passport_number",
        config: %{
          base: %{label: "Passport Number"},
          AU: %{order: 1},
          GB: %{order: 2},
          MX: %{label: "Número de Pasaporte", order: 1},
          SG: %{order: 1},
          AE: %{order: 2},
          HK: %{order: 2}
        },
        country: [australia, united_kingdom, mexico, singapore, uae, hong_kong],
        form_id: eeww_identification_info_form.id
      },
      %{
        slug: "passport-issuing-country",
        type: :text,
        optional: true,
        source_table: "users",
        source_table_field: "country_specific_fields.passport_issuing_country",
        config: %{
          base: %{label: "Passport Issuing Country"},
          AU: %{order: 2},
          GB: %{order: 3},
          MX: %{order: 2},
          SG: %{order: 2},
          AE: %{order: 3},
          HK: %{order: 3}
        },
        country: [australia, united_kingdom, mexico, singapore, uae, hong_kong],
        form_id: eeww_identification_info_form.id
      },
      %{
        slug: "passport-issue-date",
        type: :date,
        optional: true,
        source_table: "users",
        source_table_field: "country_specific_fields.passport_issue_date",
        config: %{
          base: %{label: "Passport Issue Date"},
          AU: %{order: 3},
          GB: %{order: 4},
          MX: %{order: 3},
          SG: %{order: 3},
          AE: %{order: 4},
          HK: %{order: 4}
        },
        country: [australia, united_kingdom, mexico, singapore, uae, hong_kong],
        form_id: eeww_identification_info_form.id
      },
      %{
        slug: "passport-expiration-date",
        type: :date,
        optional: true,
        source_table: "users",
        source_table_field: "country_specific_fields.passport_expiration_date",
        config: %{
          base: %{label: "Passport Expiration Date"},
          AU: %{order: 4},
          GB: %{order: 5},
          MX: %{order: 4},
          SG: %{order: 4},
          AE: %{order: 5},
          HK: %{order: 5}
        },
        country: [australia, united_kingdom, mexico, singapore, uae, hong_kong],
        form_id: eeww_identification_info_form.id
      },
      %{
        slug: "provident-fund-contribution",
        type: :number,
        optional: true,
        source_table: "users",
        source_table_field: "country_specific_fields.provident_fund_contribution",
        config: %{
          SG: %{label: "Central Provident Fund Voluntary Contribution", order: 1},
          HK: %{label: "Mandatory Provident Fund Voluntary Employee Contribution", order: 1}
        },
        country: [singapore, hong_kong],
        form_id: eeww_other_info_form.id
      },
      %{
        slug: "residency-status",
        type: :text,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.residency_status",
        config: %{
          base: %{label: "Residency Status"},
          SG: %{order: 6},
          HK: %{order: 6}
        },
        country: [singapore, hong_kong],
        form_id: eeww_other_info_form.id
      },
      %{
        slug: "residence-start-date",
        type: :date,
        optional: true,
        source_table: "users",
        source_table_field: "country_specific_fields.residence_start_date",
        config: %{
          base: %{label: "Permenant Residence Start Date"},
          SG: %{order: 7},
          HK: %{order: 7}
        },
        country: [singapore, hong_kong],
        form_id: eeww_identification_info_form.id
      },
      %{
        slug: "religion",
        type: :text,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.religion",
        config: %{
          base: %{label: "Religion"},
          SG: %{order: 2},
          AE: %{order: 1}
        },
        country: [singapore, uae],
        form_id: [eeww_personal_info_form.id, eeprofile_personal_info_form.id]
      },
      %{
        slug: "fathers-name",
        type: :text,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.fathers_name",
        config: %{
          base: %{label: "Father's Name"},
          AE: %{order: 2},
          IN: %{order: 1}
        },
        country: [india, uae],
        form_id: eeww_other_info_form.id
      },
      %{
        slug: "dependent-1-name",
        type: :text,
        optional: true,
        source_table: "users",
        source_table_field: "country_specific_fields.dependent_1_name",
        config: %{
          base: %{label: "Dependent 1 Full Name"},
          BR: %{order: 7},
          IT: %{order: 1},
          MX: %{order: 4},
          KR: %{order: 1},
          AE: %{order: 7}
        },
        country: [brazil, italy, mexico, south_korea, uae],
        form_id: [eeww_personal_info_form.id, eeprofile_personal_info_form.id]
      },
      %{
        slug: "dependent-1-birth",
        type: :date,
        optional: true,
        source_table: "users",
        source_table_field: "country_specific_fields.dependent_1_birth",
        config: %{
          base: %{label: "Dependent 1 Date of Birth"},
          BR: %{order: 8},
          IT: %{order: 2},
          MX: %{order: 5},
          KR: %{order: 2},
          AE: %{order: 8}
        },
        country: [brazil, italy, mexico, south_korea, uae],
        form_id: [eeww_personal_info_form.id, eeprofile_personal_info_form.id]
      },
      %{
        slug: "dependent-1-gender",
        type: :text,
        optional: true,
        source_table: "users",
        source_table_field: "country_specific_fields.dependent_1_gender",
        config: %{
          base: %{label: "Dependent 1 Gender"},
          IT: %{order: 3},
          MX: %{order: 6}
        },
        country: [italy, mexico],
        form_id: [eeww_personal_info_form.id, eeprofile_personal_info_form.id]
      },
      %{
        slug: "dependent-1-passport-number",
        type: :text,
        optional: true,
        source_table: "users",
        source_table_field: "country_specific_fields.dependent_1_passport_number",
        config: %{
          base: %{label: "Dependent 1 Passport Number"},
          BR: %{order: 9},
          IT: %{order: 4},
          MX: %{order: 7},
          KR: %{order: 3},
          AE: %{order: 9}
        },
        country: [brazil, italy, mexico, south_korea, uae],
        form_id: [eeww_personal_info_form.id, eeprofile_personal_info_form.id]
      },
      %{
        slug: "dependent-1-passport-issue-date",
        type: :date,
        optional: true,
        source_table: "users",
        source_table_field: "country_specific_fields.dependent_1_passport_issue_date",
        config: %{
          base: %{label: "Dependent 1 Passport Issue Date"},
          BR: %{order: 10},
          IT: %{order: 5},
          MX: %{order: 8},
          KR: %{order: 4},
          AE: %{order: 10}
        },
        country: [brazil, italy, mexico, south_korea, uae],
        form_id: [eeww_personal_info_form.id, eeprofile_personal_info_form.id]
      },
      %{
        slug: "dependent-1-passport-expiry-date",
        type: :date,
        optional: true,
        source_table: "users",
        source_table_field: "country_specific_fields.dependent_1_passport_expiry_date",
        config: %{
          base: %{label: "Dependent 1 Passport Expiry Date"},
          BR: %{order: 11},
          IT: %{order: 6},
          MX: %{order: 9},
          KR: %{order: 5},
          AE: %{order: 11}
        },
        country: [brazil, italy, mexico, south_korea, uae],
        form_id: [eeww_personal_info_form.id, eeprofile_personal_info_form.id]
      },
      %{
        slug: "dependent-2-name",
        type: :text,
        optional: true,
        source_table: "users",
        source_table_field: "country_specific_fields.dependent_2_name",
        config: %{
          base: %{label: "Dependent 2 Full Name"},
          BR: %{order: 13},
          IT: %{order: 7},
          MX: %{order: 10},
          KR: %{order: 6},
          AE: %{order: 16}
        },
        country: [brazil, italy, mexico, south_korea, uae],
        form_id: [eeww_personal_info_form.id, eeprofile_personal_info_form.id]
      },
      %{
        slug: "dependent-2-birth",
        type: :date,
        optional: true,
        source_table: "users",
        source_table_field: "country_specific_fields.dependent_2_birth",
        config: %{
          base: %{label: "Dependent 2 Date of Birth"},
          BR: %{order: 14},
          IT: %{order: 8},
          MX: %{order: 11},
          KR: %{order: 7},
          AE: %{order: 17}
        },
        country: [brazil, italy, mexico, south_korea, uae],
        form_id: [eeww_personal_info_form.id, eeprofile_personal_info_form.id]
      },
      %{
        slug: "dependent-2-gender",
        type: :text,
        optional: true,
        source_table: "users",
        source_table_field: "country_specific_fields.dependent_2_gender",
        config: %{
          base: %{label: "Dependent 2 Gender"},
          IT: %{order: 9},
          MX: %{order: 12}
        },
        country: [italy, mexico],
        form_id: [eeww_personal_info_form.id, eeprofile_personal_info_form.id]
      },
      %{
        slug: "dependent-2-passport-number",
        type: :text,
        optional: true,
        source_table: "users",
        source_table_field: "country_specific_fields.dependent_2_passport_number",
        config: %{
          base: %{label: "Dependent 2 Passport Number"},
          BR: %{order: 15},
          IT: %{order: 10},
          MX: %{order: 13},
          KR: %{order: 8},
          AE: %{order: 18}
        },
        country: [brazil, italy, mexico, south_korea, uae],
        form_id: [eeww_personal_info_form.id, eeprofile_personal_info_form.id]
      },
      %{
        slug: "dependent-2-passport-issue-date",
        type: :date,
        optional: true,
        source_table: "users",
        source_table_field: "country_specific_fields.dependent_2_passport_issue_date",
        config: %{
          base: %{label: "Dependent 2 Passport Issue Date"},
          BR: %{order: 16},
          IT: %{order: 11},
          MX: %{order: 14},
          KR: %{order: 9},
          AE: %{order: 19}
        },
        country: [brazil, italy, mexico, south_korea, uae],
        form_id: [eeww_personal_info_form.id, eeprofile_personal_info_form.id]
      },
      %{
        slug: "dependent-2-passport-expiry-date",
        type: :date,
        optional: true,
        source_table: "users",
        source_table_field: "country_specific_fields.dependent_2_passport_expiry_date",
        config: %{
          base: %{label: "Dependent 2 Passport Expiry Date"},
          BR: %{order: 17},
          IT: %{order: 12},
          MX: %{order: 15},
          KR: %{order: 10},
          AE: %{order: 20}
        },
        country: [brazil, italy, mexico, south_korea, uae],
        form_id: [eeww_personal_info_form.id, eeprofile_personal_info_form.id]
      },
      %{
        slug: "dependent-3-name",
        type: :text,
        optional: true,
        source_table: "users",
        source_table_field: "country_specific_fields.dependent_3_name",
        config: %{
          base: %{label: "Dependent 3 Full Name"},
          BR: %{order: 19},
          IT: %{order: 13},
          MX: %{order: 16},
          KR: %{order: 11},
          AE: %{order: 25}
        },
        country: [brazil, italy, mexico, south_korea, uae],
        form_id: [eeww_personal_info_form.id, eeprofile_personal_info_form.id]
      },
      %{
        slug: "dependent-3-birth",
        type: :date,
        optional: true,
        source_table: "users",
        source_table_field: "country_specific_fields.dependent_3_birth",
        config: %{
          base: %{label: "Dependent 3 Date of Birth"},
          BR: %{order: 20},
          IT: %{order: 14},
          MX: %{order: 17},
          KR: %{order: 12},
          AE: %{order: 26}
        },
        country: [brazil, italy, mexico, south_korea, uae],
        form_id: [eeww_personal_info_form.id, eeprofile_personal_info_form.id]
      },
      %{
        slug: "dependent-3-gender",
        type: :text,
        optional: true,
        source_table: "users",
        source_table_field: "country_specific_fields.dependent_3_gender",
        config: %{
          base: %{label: "Dependent 3 Gender"},
          IT: %{order: 15},
          MX: %{order: 18}
        },
        country: [italy, mexico],
        form_id: [eeww_personal_info_form.id, eeprofile_personal_info_form.id]
      },
      %{
        slug: "dependent-3-passport-number",
        type: :text,
        optional: true,
        source_table: "users",
        source_table_field: "country_specific_fields.dependent_3_passport_number",
        config: %{
          base: %{label: "Dependent 3 Passport Number"},
          BR: %{order: 21},
          IT: %{order: 16},
          MX: %{order: 19},
          KR: %{order: 13},
          AE: %{order: 27}
        },
        country: [brazil, italy, mexico, south_korea, uae],
        form_id: [eeww_personal_info_form.id, eeprofile_personal_info_form.id]
      },
      %{
        slug: "dependent-3-passport-issue-date",
        type: :date,
        optional: true,
        source_table: "users",
        source_table_field: "country_specific_fields.dependent_3_passport_issue_date",
        config: %{
          base: %{label: "Dependent 3 Passport Issue Date"},
          BR: %{order: 22},
          IT: %{order: 17},
          MX: %{order: 20},
          KR: %{order: 14},
          AE: %{order: 28}
        },
        country: [brazil, italy, mexico, south_korea, uae],
        form_id: [eeww_personal_info_form.id, eeprofile_personal_info_form.id]
      },
      %{
        slug: "dependent-3-passport-expiry-date",
        type: :date,
        optional: true,
        source_table: "users",
        source_table_field: "country_specific_fields.dependent_3_passport_expiry_date",
        config: %{
          base: %{label: "Dependent 3 Passport Expiry Date"},
          BR: %{order: 23},
          IT: %{order: 18},
          MX: %{order: 21},
          KR: %{order: 15},
          AE: %{order: 29}
        },
        country: [brazil, italy, mexico, south_korea, uae],
        form_id: [eeww_personal_info_form.id, eeprofile_personal_info_form.id]
      },
      %{
        slug: "dependent-4-name",
        type: :text,
        optional: true,
        source_table: "users",
        source_table_field: "country_specific_fields.dependent_4_name",
        config: %{
          base: %{label: "Dependent 4 Full Name"},
          BR: %{order: 25},
          IT: %{order: 19},
          MX: %{order: 22},
          KR: %{order: 16},
          AE: %{order: 34}
        },
        country: [brazil, italy, mexico, south_korea, uae],
        form_id: [eeww_personal_info_form.id, eeprofile_personal_info_form.id]
      },
      %{
        slug: "dependent-4-birth",
        type: :date,
        optional: true,
        source_table: "users",
        source_table_field: "country_specific_fields.dependent_4_birth",
        config: %{
          base: %{label: "Dependent 4 Date of Birth"},
          BR: %{order: 26},
          IT: %{order: 20},
          MX: %{order: 23},
          KR: %{order: 17},
          AE: %{order: 35}
        },
        country: [brazil, italy, mexico, south_korea, uae],
        form_id: [eeww_personal_info_form.id, eeprofile_personal_info_form.id]
      },
      %{
        slug: "dependent-4-gender",
        type: :text,
        optional: true,
        source_table: "users",
        source_table_field: "country_specific_fields.dependent_4_gender",
        config: %{
          base: %{label: "Dependent 4 Gender"},
          IT: %{order: 21},
          MX: %{order: 24}
        },
        country: [italy, mexico],
        form_id: [eeww_personal_info_form.id, eeprofile_personal_info_form.id]
      },
      %{
        slug: "dependent-4-passport-number",
        type: :text,
        optional: true,
        source_table: "users",
        source_table_field: "country_specific_fields.dependent_4_passport_number",
        config: %{
          base: %{label: "Dependent 4 Passport Number"},
          BR: %{order: 27},
          IT: %{order: 22},
          MX: %{order: 25},
          KR: %{order: 18},
          AE: %{order: 36}
        },
        country: [brazil, italy, mexico, south_korea, uae],
        form_id: [eeww_personal_info_form.id, eeprofile_personal_info_form.id]
      },
      %{
        slug: "dependent-4-passport-issue-date",
        type: :date,
        optional: true,
        source_table: "users",
        source_table_field: "country_specific_fields.dependent_4_passport_issue_date",
        config: %{
          base: %{label: "Dependent 4 Passport Issue Date"},
          BR: %{order: 28},
          IT: %{order: 23},
          MX: %{order: 26},
          KR: %{order: 19},
          AE: %{order: 37}
        },
        country: [brazil, italy, mexico, south_korea, uae],
        form_id: [eeww_personal_info_form.id, eeprofile_personal_info_form.id]
      },
      %{
        slug: "dependent-4-passport-expiry-date",
        type: :date,
        optional: true,
        source_table: "users",
        source_table_field: "country_specific_fields.dependent_4_passport_expiry_date",
        config: %{
          base: %{label: "Dependent 4 Passport Expiry Date"},
          BR: %{order: 29},
          IT: %{order: 24},
          MX: %{order: 27},
          KR: %{order: 20},
          AE: %{order: 38}
        },
        country: [brazil, italy, mexico, south_korea, uae],
        form_id: [eeww_personal_info_form.id, eeprofile_personal_info_form.id]
      },
      %{
        slug: "spouse-name",
        type: :text,
        optional: true,
        source_table: "users",
        source_table_field: "country_specific_fields.spouse_name",
        config: %{
          base: %{label: "Spouse's Name"},
          IN: %{order: 2},
          MX: %{label: "Nombre del Cónyuge", order: 1}
        },
        country: [india, mexico],
        form_id: eeww_other_info_form.id
      },
      %{
        slug: "tax-id-number",
        type: :private,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.tax_id_number",
        config: %{
          base: %{label: "Tax ID Number"},
          AU: %{order: 6},
          HK: %{label: "Tax Number", order: 1},
          ES: %{label: "Tax Number (NIF/NIE)", order: 3}
        },
        country: [australia, hong_kong, spain],
        form_id: eeww_identification_info_form.id
      },
      %{
        slug: "voluntary-deductions",
        type: :number,
        optional: true,
        source_table: "users",
        source_table_field: "country_specific_fields.voluntary_deductions",
        config: %{
          base: %{label: "Voluntary Deductions"},
          NZ: %{order: 2},
          SK: %{order: 2}
        },
        country: [new_zealand, south_korea],
        form_id: [eeww_work_info_form.id, eeprofile_work_info_form.id]
      },
      %{
        slug: "tax-rebates",
        type: :text,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.tax_rebates",
        config: %{
          base: %{label: "Tax Rebates"},
          NZ: %{order: 7},
          AU: %{order: 8}
        },
        country: [new_zealand, australia],
        form_id: eeww_identification_info_form.id
      },

      #
      # Australia
      #
      %{
        slug: "tax-variation",
        type: :boolean,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.tax_variation",
        config: %{label: "Tax Variation", order: 7},
        country: australia,
        form_id: eeww_identification_info_form.id
      },
      %{
        slug: "is-australian-resident",
        type: :boolean,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.is_australian_resident",
        config: %{label: "Australian resident for tax purposes?", order: 9},
        country: australia,
        form_id: eeww_identification_info_form.id
      },
      %{
        slug: "financial-supplement-debt",
        type: :boolean,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.financial_supplement_debt",
        config: %{label: "Financial Supplement debt?", order: 1},
        country: australia,
        form_id: eeww_other_info_form.id
      },
      %{
        # Do you have HELP, SSL, or TSL debt? (Y/N)
        slug: "has-debts",
        type: :boolean,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.has_debts",
        config: %{label: "Do you have HELP, SSL, or TSL debt?", order: 2},
        country: australia,
        form_id: eeww_other_info_form.id
      },
      %{
        slug: "medicare-levy-exemption",
        type: :boolean,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.medicare_levy_exemption",
        config: %{label: "Medicare Levy Exemption if applicable?", order: 3},
        country: australia,
        form_id: eeww_other_info_form.id
      },
      %{
        slug: "type-of-superannuation",
        type: :text,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.type_of_superannuation",
        config: %{label: "Type of Superannuation", order: 4},
        country: australia,
        form_id: eeww_other_info_form.id
      },
      %{
        slug: "number-superannuation-accounts",
        type: :text,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.number_superannuation_accounts",
        config: %{label: "Number of Superannuation Accounts", order: 5},
        country: australia,
        form_id: eeww_other_info_form.id
      },
      %{
        slug: "spin-number",
        type: :number,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.spin_number",
        config: %{label: "Fund Name/SPIN Number", order: 6},
        country: australia,
        form_id: eeww_other_info_form.id
      },
      %{
        slug: "superannuation-product-code",
        type: :number,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.superannuation_product_code",
        config: %{label: "Superannuation Product Code", order: 7},
        country: australia,
        form_id: eeww_other_info_form.id
      },
      %{
        slug: "superannuation-membership-number",
        type: :number,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.superannuation_membership_number",
        config: %{label: "Superannuaton Membership number", order: 8},
        country: australia,
        form_id: eeww_other_info_form.id
      },
      %{
        slug: "superannuation-employee-contribution",
        type: :number,
        optional: true,
        source_table: "users",
        source_table_field: "country_specific_fields.superannuation_employee_contribution",
        config: %{label: "Superannuation Employee Contribution", order: 9},
        country: australia,
        form_id: eeww_other_info_form.id
      },
      %{
        slug: "union-name",
        type: :text,
        optional: true,
        source_table: "users",
        source_table_field: "country_specific_fields.union_name",
        config: %{label: "Union Name", order: 1},
        country: australia,
        form_id: [eeww_work_info_form.id, eeprofile_work_info_form.id]
      },
      %{
        slug: "union-membership-number",
        type: :number,
        optional: true,
        source_table: "users",
        source_table_field: "country_specific_fields.union_membership_number",
        config: %{label: "Union Membership Number", order: 2},
        country: australia,
        form_id: [eeww_work_info_form.id, eeprofile_work_info_form.id]
      },
      %{
        slug: "union-weekly-fee",
        type: :number,
        optional: true,
        source_table: "users",
        source_table_field: "country_specific_fields.union_weekly_fee",
        config: %{label: "Union Weeky Fee", order: 3},
        country: australia,
        form_id: [eeww_work_info_form.id, eeprofile_work_info_form.id]
      },
      %{
        slug: "bank-percentage-allocation",
        type: :number,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.bank_percentage_allocation",
        config: %{label: "Bank %. Allocation Preference", order: 3},
        country: australia,
        form_id: eeww_bank_info_form.id
      },
      #
      # Brazil
      #
      %{
        slug: "has-completed-university",
        type: :boolean,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.has_completed_university",
        config: %{label: "Have you completed a university degree?", order: 1},
        country: brazil,
        form_id: [eeww_personal_info_form.id, eeprofile_personal_info_form.id]
      },
      %{
        slug: "highest-degree-completed",
        type: :text,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.highest_degree_completed",
        config: %{label: "Highest Degree Type Completed", order: 2},
        country: brazil,
        form_id: [eeww_personal_info_form.id, eeprofile_personal_info_form.id]
      },
      %{
        slug: "degree-code",
        type: :number,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.degree_code",
        config: %{label: "Degree Code", order: 3},
        country: brazil,
        form_id: [eeww_personal_info_form.id, eeprofile_personal_info_form.id]
      },
      %{
        slug: "ethnicity",
        type: :text,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.ethnicity",
        config: %{label: "Ethnicity", order: 4},
        country: brazil,
        form_id: [eeww_personal_info_form.id, eeprofile_personal_info_form.id]
      },
      %{
        slug: "dependent-1-cpf",
        type: :private,
        optional: true,
        source_table: "users",
        source_table_field: "country_specific_fields.dependent_1_cpf",
        config: %{label: "Dependent 1 CPF number", order: 12},
        country: brazil,
        form_id: [eeww_personal_info_form.id, eeprofile_personal_info_form.id]
      },
      %{
        slug: "dependent-2-cpf",
        type: :private,
        optional: true,
        source_table: "users",
        source_table_field: "country_specific_fields.dependent_2_cpf",
        config: %{label: "Dependent 2 CPF number", order: 18},
        country: brazil,
        form_id: [eeww_personal_info_form.id, eeprofile_personal_info_form.id]
      },
      %{
        slug: "dependent-3-cpf",
        type: :private,
        optional: true,
        source_table: "users",
        source_table_field: "country_specific_fields.dependent_3_cpf",
        config: %{label: "Dependent 3 CPF number", order: 24},
        country: brazil,
        form_id: [eeww_personal_info_form.id, eeprofile_personal_info_form.id]
      },
      %{
        slug: "dependent-4-cpf",
        type: :private,
        optional: true,
        source_table: "users",
        source_table_field: "country_specific_fields.dependent_4_cpf",
        config: %{label: "Dependent 4 CPF number", order: 30},
        country: brazil,
        form_id: [eeww_personal_info_form.id, eeprofile_personal_info_form.id]
      },
      %{
        slug: "has-disability",
        type: :boolean,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.has_disability",
        config: %{label: "Do you identify as someone with a disability?", order: 5},
        country: brazil,
        form_id: [eeww_personal_info_form.id, eeprofile_personal_info_form.id]
      },
      %{
        slug: "disability-type",
        type: :text,
        optional: true,
        source_table: "users",
        source_table_field: "country_specific_fields.disability_type",
        config: %{label: "Disability Type If applicable", order: 6},
        country: brazil,
        form_id: [eeww_personal_info_form.id, eeprofile_personal_info_form.id]
      },
      %{
        slug: "national-qualification-card",
        type: :text,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.national_qualification_card",
        config: %{order: 1, label: "CNH Nº"},
        country: brazil,
        form_id: eeww_other_info_form.id
      },
      %{
        slug: "qualification-card-issuing-body",
        type: :text,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.qualification_card_issuing_body",
        config: %{order: 2, label: "ORGÃO EMISSOR/UF"},
        country: brazil,
        form_id: eeww_identification_info_form.id
      },
      %{
        slug: "qualification-card-issuing-date",
        type: :date,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.qualification_card_issuing_date",
        config: %{label: "DATA EMISSÃO", order: 3},
        country: brazil,
        form_id: eeww_identification_info_form.id
      },
      %{
        slug: "ctps-series",
        type: :text,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.ctps_series",
        config: %{label: "CTPS SÉRIE", order: 5},
        country: brazil,
        form_id: eeww_identification_info_form.id
      },
      %{
        slug: "social-issuing-body",
        type: :text,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.social_issuing_body",
        config: %{label: "UF", order: 6},
        country: brazil,
        form_id: eeww_identification_info_form.id
      },
      %{
        slug: "registro-geral-number",
        type: :text,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.registro_geral_number",
        config: %{label: "R.G. Nº", order: 7},
        country: brazil,
        form_id: eeww_identification_info_form.id
      },
      %{
        slug: "rgn-issuing-date",
        type: :date,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.rgn_issuing_date",
        config: %{label: "DATA DE EMISSÃO", order: 8},
        country: brazil,
        form_id: eeww_identification_info_form.id
      },
      %{
        slug: "rgn-issuing-body",
        type: :text,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.rgn_issuing_body",
        config: %{label: "ORGÃO EMISSOR /UF", order: 9},
        country: brazil,
        form_id: eeww_identification_info_form.id
      },
      %{
        slug: "social-integration-number",
        type: :text,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.social_integration_number",
        config: %{label: "PIS Nº", order: 10},
        country: brazil,
        form_id: eeww_identification_info_form.id
      },
      %{
        slug: "emission",
        type: :text,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.emission",
        config: %{label: "EMISSÃO", order: 11},
        country: brazil,
        form_id: eeww_identification_info_form.id
      },
      %{
        slug: "natural-persons-register",
        type: :private,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.national_persons_register",
        config: %{label: "C.P.F. Nº", order: 12},
        country: brazil,
        form_id: eeww_identification_info_form.id
      },
      %{
        slug: "millitary-certificate",
        type: :text,
        optional: true,
        source_table: "users",
        source_table_field: "country_specific_fields.millitary_certificate",
        config: %{label: "CERT. MILITAR", order: 1},
        country: brazil,
        form_id: eeww_other_info_form.id
      },
      %{
        slug: "voter-title",
        type: :text,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.voter_title",
        config: %{label: "TITULO DE ELEITOR", order: 2},
        country: brazil,
        form_id: eeww_other_info_form.id
      },
      %{
        slug: "zone",
        type: :text,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.zone",
        config: %{label: "ZONA", order: 3},
        country: brazil,
        form_id: eeww_other_info_form.id
      },
      %{
        slug: "section",
        type: :text,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.section",
        config: %{label: "SEÇÃO", order: 4},
        country: brazil,
        form_id: eeww_other_info_form.id
      },
      #
      # Canada
      #
      %{
        slug: "sin-number",
        type: :number,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.sin_number",
        config: %{label: "SIN Number", order: 1},
        country: canada,
        form_id: eeww_identification_info_form.id
      },
      %{
        slug: "sin-expiry",
        type: :number,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.sin_expiry",
        config: %{label: "SIN Expiry if starts with a \"9\"", order: 2},
        country: canada,
        form_id: eeww_identification_info_form.id
      },
      %{
        slug: "rrsp-contributions",
        type: :number,
        optional: true,
        source_table: "users",
        source_table_field: "country_specific_fields.rrsp_contributions",
        config: %{label: "RRSP Employee Contributions", order: 1},
        country: canada,
        form_id: [eeww_work_info_form.id, eeprofile_work_info_form.id]
      },
      %{
        slug: "health-benefits-contributions",
        type: :number,
        optional: true,
        source_table: "users",
        source_table_field: "country_specific_fields.health_benefits_contributions",
        config: %{label: "Health Benefits Employee Contributions", order: 2},
        country: canada,
        form_id: [eeww_work_info_form.id, eeprofile_work_info_form.id]
      },
      %{
        slug: "deductions-applicable",
        type: :boolean,
        optional: true,
        source_table: "users",
        source_table_field: "country_specific_fields.deductions_applicable",
        config: %{label: "Are employee deductions applicable?", order: 3},
        country: canada,
        form_id: [eeww_work_info_form.id, eeprofile_work_info_form.id]
      },
      %{
        slug: "province-of-taxation",
        type: :text,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.province_of_taxation",
        config: %{label: "Province of taxation", order: 4},
        country: canada,
        form_id: [eeww_work_info_form.id, eeprofile_work_info_form.id]
      },
      %{
        slug: "employment-insurance-type",
        type: :text,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.employment_insurance_type",
        config: %{label: "Employment Insurance Type (Normal or Reduced)", order: 1},
        country: canada,
        form_id: eeww_other_info_form.id
      },
      %{
        slug: "employment-insurance-exempt",
        type: :boolean,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.employment_insurance_exempt",
        config: %{label: "Are you employment insurance exempt?", order: 2},
        country: canada,
        form_id: eeww_other_info_form.id
      },
      %{
        slug: "cpt30-applicable",
        type: :boolean,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.cpt30_applicable",
        config: %{label: "Is CPT30 Applicable?", order: 3},
        country: canada,
        form_id: eeww_other_info_form.id
      },
      %{
        slug: "provincial-exemptions",
        type: :number,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.provincial_exemptions",
        config: %{label: "Provincial WSIB/WCB/CSST exemptions", order: 4},
        country: canada,
        form_id: eeww_other_info_form.id
      },
      %{
        slug: "td1s",
        type: :number,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.td1s",
        config: %{label: "Federal/Provincial TD1s", order: 5},
        country: canada,
        form_id: eeww_other_info_form.id
      },
      %{
        slug: "banking-institution-number",
        type: :number,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.banking_institution_number",
        config: %{label: "Banking Institution Number (3 digits)", order: 1},
        country: canada,
        form_id: eeww_bank_info_form.id
      },
      %{
        slug: "existing-client-relationship",
        type: :boolean,
        optional: true,
        source_table: "users",
        source_table_field: "country_specific_fields.existing_client_relationship",
        config: %{label: "Existing working relationship with current client?", order: 5},
        country: canada,
        form_id: [eeww_work_info_form.id, eeprofile_work_info_form.id]
      },
      #
      # Colombia
      #
      %{
        slug: "latest-medical-exam",
        type: :date,
        optional: true,
        source_table: "users",
        source_table_field: "country_specific_fields.latest_medical_exam",
        config: %{label: "Latest Medical Exam Date", order: 1},
        country: colombia,
        form_id: eeww_other_info_form.id
      },
      %{
        slug: "colmedica-enroll-date",
        type: :date,
        optional: true,
        source_table: "users",
        source_table_field: "country_specific_fields.colmedica_enroll_date",
        config: %{label: "Colmedica Enrollment Date", order: 2},
        country: colombia,
        form_id: eeww_other_info_form.id
      },
      %{
        slug: "current-health-provider",
        type: :text,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.current_health_provider",
        config: %{label: "Current Empresa Prestadora de Salud", order: 3},
        country: colombia,
        form_id: eeww_other_info_form.id
      },
      %{
        slug: "private-insurance-name",
        type: :text,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.private_insurance_name",
        config: %{label: "Private health insurance company name", order: 4},
        country: colombia,
        form_id: eeww_other_info_form.id
      },
      %{
        slug: "mandatory-pension-name",
        type: :text,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.mandatory_pension_name",
        config: %{label: "Name of the mandatory pension fund", order: 5},
        country: colombia,
        form_id: eeww_other_info_form.id
      },
      %{
        slug: "voluntary-pension-name",
        type: :text,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.voluntary_pension_name",
        config: %{label: "Name of the voluntary pension fund", order: 6},
        country: colombia,
        form_id: eeww_other_info_form.id
      },
      %{
        slug: "voluntary-pension-amount",
        type: :number,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.voluntary_pension_amount",
        config: %{label: "Voluntary pension contribution amount", order: 7},
        country: colombia,
        form_id: eeww_other_info_form.id
      },
      %{
        slug: "welfare-fund-name",
        type: :text,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.welfare_fund_name",
        config: %{label: "Welfare Fund Name", order: 8},
        country: colombia,
        form_id: eeww_other_info_form.id
      },
      %{
        slug: "savings-promotion-construction",
        type: :text,
        optional: true,
        source_table: "users",
        source_table_field: "country_specific_fields.savings_promotion_contribution",
        config: %{label: "Ahorro Fomento Construcción", order: 1},
        country: colombia,
        form_id: eeww_bank_info_form.id
      },
      %{
        slug: "savings-promotion-construction-account",
        type: :number,
        optional: true,
        source_table: "users",
        source_table_field: "country_specific_fields.savings_promotion_contribution_account",
        config: %{label: "Ahorro Fomento Construcción account number", order: 2},
        country: colombia,
        form_id: eeww_bank_info_form.id
      },
      %{
        slug: "savings-promotion-construction-amount",
        type: :number,
        optional: true,
        source_table: "users",
        source_table_field: "country_specific_fields.savings_promotion_contribution_amount",
        config: %{label: "Ahorro Fomento Construcción monthly amount contribution", order: 3},
        country: colombia,
        form_id: eeww_bank_info_form.id
      },
      %{
        slug: "spouse-first-name",
        type: :text,
        optional: true,
        source_table: "users",
        source_table_field: "country_specific_fields.spouse_first_name",
        config: %{label: "Spouse First Name", order: 1},
        country: colombia,
        form_id: [eeww_personal_info_form.id, eeprofile_personal_info_form.id]
      },
      %{
        slug: "spouse-last-name",
        type: :text,
        optional: true,
        source_table: "users",
        source_table_field: "country_specific_fields.spouse_last_name",
        config: %{label: "Spouse Last Name", order: 2},
        country: colombia,
        form_id: [eeww_personal_info_form.id, eeprofile_personal_info_form.id]
      },
      %{
        slug: "spouse-personal-email",
        type: :text,
        optional: true,
        source_table: "users",
        source_table_field: "country_specific_fields.spouse_personal_email",
        config: %{label: "Spouse Personal Email", order: 3},
        country: colombia,
        form_id: [eeww_personal_info_form.id, eeprofile_personal_info_form.id]
      },
      %{
        slug: "spouse-position",
        type: :text,
        optional: true,
        source_table: "users",
        source_table_field: "country_specific_fields.spouse_position",
        config: %{label: "Spouse Position", order: 4},
        country: colombia,
        form_id: [eeww_personal_info_form.id, eeprofile_personal_info_form.id]
      },
      %{
        slug: "integral-ordinal-salary",
        type: :text,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.integral_ordinal_salary",
        config: %{label: "Integral or Ordinary Salary?", order: 1},
        country: colombia,
        form_id: [eeww_work_info_form.id, eeprofile_work_info_form.id]
      },
      #
      # France
      #
      %{
        slug: "national-id-card",
        type: :number,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.national_id_card",
        config: %{label: "Carte Nationale D'Identite", order: 1},
        country: france,
        form_id: eeww_identification_info_form.id
      },
      %{
        slug: "card-valid-until",
        type: :date,
        optional: true,
        source_table: "users",
        source_table_field: "country_specific_fields.card_valid_until",
        config: %{label: "Carte valable Jusqu'au", order: 2},
        country: france,
        form_id: eeww_identification_info_form.id
      },
      %{
        slug: "issued-on",
        type: :date,
        optional: true,
        source_table: "users",
        source_table_field: "country_specific_fields.issued_on",
        config: %{label: "Delivree le", order: 3},
        country: france,
        form_id: eeww_identification_info_form.id
      },
      %{
        slug: "social-security-affiliate-body",
        type: :number,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.social_security_affiliate_body",
        config: %{label: "Organisme de rattachement securite sociale", order: 4},
        country: france,
        form_id: eeww_identification_info_form.id
      },
      %{
        slug: "management-code",
        type: :number,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.management_code",
        config: %{label: "Code Gestion", order: 5},
        country: france,
        form_id: eeww_identification_info_form.id
      },
      %{
        slug: "job-title",
        type: :text,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.job_title",
        config: %{label: "Job title (only given by the collective agreement)", order: 1},
        country: france,
        form_id: [eeww_work_info_form.id, eeprofile_work_info_form.id]
      },
      %{
        slug: "qualification",
        type: :text,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.qualification",
        config: %{label: "Qualification (Job Title particular to the company)", order: 2},
        country: france,
        form_id: [eeww_work_info_form.id, eeprofile_work_info_form.id]
      },
      %{
        slug: "category",
        type: :text,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.category",
        config: %{label: "Category (Manager, Employee)", order: 3},
        country: france,
        form_id: [eeww_work_info_form.id, eeprofile_work_info_form.id]
      },
      %{
        slug: "coefficient",
        type: :number,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.coefficient",
        config: %{label: "Coefficient", order: 4},
        country: france,
        form_id: [eeww_work_info_form.id, eeprofile_work_info_form.id]
      },
      %{
        slug: "level",
        type: :text,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.level",
        config: %{label: "Level", order: 5},
        country: france,
        form_id: [eeww_work_info_form.id, eeprofile_work_info_form.id]
      },
      %{
        slug: "position",
        type: :text,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.position",
        config: %{label: "Position", order: 6},
        country: france,
        form_id: [eeww_work_info_form.id, eeprofile_work_info_form.id]
      },
      %{
        slug: "rating",
        type: :text,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.rating",
        config: %{label: "Rating", order: 7},
        country: france,
        form_id: [eeww_work_info_form.id, eeprofile_work_info_form.id]
      },
      %{
        slug: "grade",
        type: :text,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.grade",
        config: %{label: "Grade", order: 8},
        country: france,
        form_id: [eeww_work_info_form.id, eeprofile_work_info_form.id]
      },
      #
      # United Kingdom
      #
      %{
        slug: "sort-code",
        type: :number,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.sort_code",
        config: %{label: "Sort Code", order: 1},
        country: united_kingdom,
        form_id: eeww_bank_info_form.id
      },
      %{
        slug: "national-insurance-number",
        type: :number,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.national_insurance_number",
        config: %{label: "National Insurance Number", order: 1},
        country: united_kingdom,
        form_id: eeww_identification_info_form.id
      },
      %{
        slug: "work-permit-number",
        type: :number,
        optional: true,
        source_table: "users",
        source_table_field: "country_specific_fields.work_permit_number",
        config: %{label: "Work Permit Number (if applicable)", order: 6},
        country: united_kingdom,
        form_id: eeww_identification_info_form.id
      },
      %{
        slug: "student-loan-repayment",
        type: :text,
        optional: true,
        source_table: "users",
        source_table_field: "country_specific_fields.student_loan_repayment",
        config: %{label: "Student Loan Repayment Plan", order: 1},
        country: united_kingdom,
        form_id: eeww_other_info_form.id
      },
      #
      # Hong Kong
      #
      %{
        slug: "hong-kong-id",
        type: :number,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.hong_kong_id",
        config: %{label: "Hong Kong ID Number", order: 1},
        country: hong_kong,
        form_id: eeww_other_info_form.id
      },
      %{
        slug: "spouse-hong-kong-id",
        type: :number,
        optional: true,
        source_table: "users",
        source_table_field: "country_specific_fields.spouse_hong_kong_id",
        config: %{label: "Spouse Hong Kong ID Number", order: 2},
        country: hong_kong,
        form_id: eeww_other_info_form.id
      },
      #
      # India
      #
      %{
        slug: "highest-educational-qualification",
        type: :text,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.highest_educational_qualification",
        config: %{label: "Highest Educational Qualification", order: 1},
        country: india,
        form_id: [eeww_personal_info_form.id, eeprofile_personal_info_form.id]
      },
      %{
        slug: "aadhar-number",
        type: :number,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.aadhar_number",
        config: %{label: "Aadhar Number", order: 1},
        country: india,
        form_id: eeww_identification_info_form.id
      },
      %{
        slug: "pan-card-number",
        type: :number,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.pan_card_number",
        config: %{label: "PAN Card Number", order: 2},
        country: india,
        form_id: eeww_identification_info_form.id
      },
      %{
        slug: "uan-number",
        type: :number,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.uan_number",
        config: %{label: "UAN Number", order: 3},
        country: india,
        form_id: eeww_identification_info_form.id
      },
      %{
        slug: "provident-fund-nominees",
        type: :text,
        optional: true,
        source_table: "users",
        source_table_field: "country_specific_fields.provident_fund_nominees",
        config: %{label: "Provident Fund Nominee(s)", order: 3},
        country: india,
        form_id: eeww_other_info_form.id
      },
      %{
        slug: "relationship-to-nominee",
        type: :text,
        optional: true,
        source_table: "users",
        source_table_field: "country_specific_fields.relationship_to_nominee",
        config: %{label: "Relationship to Nominee", order: 4},
        country: india,
        form_id: eeww_other_info_form.id
      },
      %{
        slug: "ifsc-code",
        type: :number,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.ifsc_code",
        config: %{label: "IFSC Code", order: 2},
        country: india,
        form_id: eeww_bank_info_form.id
      },
      #
      # Italy
      #
      %{
        slug: "nif-number",
        type: :number,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.nif_number",
        config: %{label: "NIF Number", order: 1},
        country: italy,
        form_id: eeww_identification_info_form.id
      },
      %{
        slug: "bank-routing-number",
        type: :number,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.bank_routing_number",
        config: %{label: "Bank Routing Number", order: 1},
        country: italy,
        form_id: eeww_bank_info_form.id
      },
      #
      # Mexico
      #
      %{
        slug: "spouse-birth",
        type: :date,
        optional: true,
        source_table: "users",
        source_table_field: "country_specific_fields.spouse_birth",
        config: %{label: "Fecha de nacimiento del Cónyuge", order: 2},
        country: mexico,
        form_id: [eeww_personal_info_form.id, eeprofile_personal_info_form.id]
      },
      %{
        slug: "spouse-phone",
        type: :phone,
        optional: true,
        source_table: "users",
        source_table_field: "country_specific_fields.spouse_phone",
        config: %{label: "Número celular del Cónyuge", order: 3},
        country: mexico,
        form_id: [eeww_personal_info_form.id, eeprofile_personal_info_form.id]
      },
      %{
        slug: "university-achieved",
        type: :boolean,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.university_achieved",
        config: %{label: "University Acheived?", order: 1},
        country: mexico,
        form_id: eeww_other_info_form.id
      },
      %{
        slug: "masters-achieved",
        type: :boolean,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.masters_achieved",
        config: %{label: "Master's Achieved?", order: 2},
        country: mexico,
        form_id: eeww_other_info_form.id
      },
      %{
        slug: "doctorate-achieved",
        type: :boolean,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.doctorate_achieved",
        config: %{label: "Doctorate Achieved?", order: 3},
        country: mexico,
        form_id: eeww_other_info_form.id
      },
      %{
        slug: "languages-spoken",
        type: :text,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.languages_spoken",
        config: %{label: "Languages Spoken", order: 4},
        country: mexico,
        form_id: eeww_other_info_form.id
      },
      %{
        slug: "school-name",
        type: :text,
        optional: true,
        source_table: "users",
        source_table_field: "country_specific_fields.school_name",
        config: %{label: "School Name", order: 5},
        country: mexico,
        form_id: eeww_other_info_form.id
      },
      %{
        slug: "professional-specialty",
        type: :text,
        optional: true,
        source_table: "users",
        source_table_field: "country_specific_fields.professional_specialty",
        config: %{label: "Professional Specialty", order: 6},
        country: mexico,
        form_id: eeww_other_info_form.id
      },
      %{
        slug: "infonavit",
        type: :number,
        optional: true,
        source_table: "users",
        source_table_field: "country_specific_fields.infonavit",
        config: %{label: "INFONAVIT", order: 7},
        country: mexico,
        form_id: eeww_other_info_form.id
      },
      %{
        slug: "fonacot",
        type: :number,
        optional: true,
        source_table: "users",
        source_table_field: "country_specific_fields.fonacot",
        config: %{label: "FONACOT", order: 8},
        country: mexico,
        form_id: eeww_other_info_form.id
      },
      %{
        slug: "clabe",
        type: :number,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.clabe",
        config: %{label: "CLABE", order: 1},
        country: mexico,
        form_id: eeww_bank_info_form.id
      },
      %{
        slug: "registro-federal",
        type: :private,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.registro_federal",
        config: %{label: "Registro Federal de Contribuyentes", order: 6},
        country: mexico,
        form_id: eeww_identification_info_form.id
      },
      %{
        slug: "unique-citizen-code",
        type: :number,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.unique_citizen_code",
        config: %{label: "Unique Citizen Code", order: 7},
        country: mexico,
        form_id: eeww_identification_info_form.id
      },

      #
      # Netherlands
      #
      %{
        slug: "place-of-birth",
        type: :text,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.place_of_birth",
        config: %{label: "Place of Birth", order: 2},
        country: netherlands,
        form_id: eeww_identification_info_form.id
      },
      %{
        slug: "country-of-birth",
        type: :text,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.country_of_birth",
        config: %{label: "Country of Birth", order: 3},
        country: netherlands,
        form_id: eeww_identification_info_form.id
      },
      %{
        slug: "social-security-applied",
        type: :boolean,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.social_security_applied",
        config: %{label: "Is Your Social Security Applied in the Netherlands?", order: 4},
        country: netherlands,
        form_id: eeww_identification_info_form.id
      },
      %{
        slug: "wage-tax-applied",
        type: :boolean,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.wage_tax_applied",
        config: %{label: "Is Your Wage Tax applied in the Netherlands?", order: 5},
        country: netherlands,
        form_id: [eeww_work_info_form.id, eeprofile_work_info_form.id]
      },
      %{
        slug: "30-percent-ruling",
        type: :boolean,
        optional: true,
        source_table: "users",
        source_table_field: "country_specific_fields.30_percent_ruling",
        config: %{label: "30% Ruling", order: 2},
        country: netherlands,
        form_id: [eeww_work_info_form.id, eeprofile_work_info_form.id]
      },
      %{
        slug: "apply-levy-rebate",
        type: :boolean,
        optional: true,
        source_table: "users",
        source_table_field: "country_specific_fields.apply_levy_rebate",
        config: %{label: "Apply Levy Rebate in Payroll", order: 3},
        country: netherlands,
        form_id: [eeww_work_info_form.id, eeprofile_work_info_form.id]
      },
      #
      # New Zealand
      #
      %{
        slug: "tax-code",
        type: :text,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.tax_code",
        config: %{label: "Tax Code", order: 6},
        country: new_zealand,
        form_id: eeww_identification_info_form.id
      },
      %{
        slug: "inland-revenue-number",
        type: :private,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.inland_revenue_number",
        config: %{label: "Inland Revenue Department Number", order: 1},
        country: new_zealand,
        form_id: [eeww_work_info_form.id, eeprofile_work_info_form.id]
      },
      %{
        slug: "kiwi-saver-optout",
        type: :boolean,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.kiwi_saver_optout",
        config: %{label: "Opt Out of KiwiSaver?", order: 1},
        country: new_zealand,
        form_id: eeww_other_info_form.id
      },
      %{
        slug: "kiwi-saver-fund",
        type: :text,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.kiwi_saver_fund",
        config: %{label: "KiwiSaver Fund Name", order: 2},
        country: new_zealand,
        form_id: eeww_other_info_form.id
      },
      %{
        slug: "kiwi-saver-number",
        type: :private,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.kiwi_saver_number",
        config: %{label: "KiwiSaver Number", order: 3},
        country: new_zealand,
        form_id: eeww_other_info_form.id
      },
      %{
        slug: "employee-contribution",
        type: :number,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.employee_contribution",
        config: %{label: "Employee Contribution", order: 4},
        country: new_zealand,
        form_id: eeww_other_info_form.id
      },
      %{
        slug: "employer-superannuation",
        type: :number,
        optional: true,
        source_table: "users",
        source_table_field: "country_specific_fields.employer_superannuation",
        config: %{label: "Employer Supperannuation Contribution Tax", order: 5},
        country: new_zealand,
        form_id: eeww_other_info_form.id
      },
      %{
        slug: "child-support-start",
        type: :date,
        optional: true,
        source_table: "users",
        source_table_field: "country_specific_fields.child_support_start",
        config: %{label: "Child Support Start Date (if applicable)", order: 6},
        country: new_zealand,
        form_id: eeww_other_info_form.id
      },
      %{
        slug: "child-support-amount",
        type: :number,
        optional: true,
        source_table: "users",
        source_table_field: "country_specific_fields.child_support_amount",
        config: %{label: "Child Support amount/pay (if applicable)", order: 7},
        country: new_zealand,
        form_id: eeww_other_info_form.id
      },
      %{
        slug: "suffix-number",
        type: :number,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.suffix_number",
        config: %{label: "Suffix Number", order: 2},
        country: new_zealand,
        form_id: eeww_bank_info_form.id
      },
      #
      # Singapore
      #
      %{
        slug: "race",
        type: :text,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.race",
        config: %{label: "Race", order: 1},
        country: singapore,
        form_id: [eeww_personal_info_form.id, eeprofile_personal_info_form.id]
      },
      %{
        slug: "cultural-fund-contribution",
        type: :text,
        optional: true,
        source_table: "users",
        source_table_field: "country_specific_fields.cultural_fund_contribution",
        config: %{label: "What Cultural Fund Would You Like To Contribute To?", order: 1},
        country: singapore,
        form_id: eeww_other_info_form.id
      },
      %{
        slug: "nric-number",
        type: :text,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.nric_number",
        config: %{label: "NRIC/FIN Number", order: 5},
        country: singapore,
        form_id: eeww_identification_info_form.id
      },
      #
      # Spain
      #

      #
      # South Korea
      #
      %{
        slug: "employee-pid",
        type: :number,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.employee_pid",
        config: %{label: "Employee PID", order: 1},
        country: south_korea,
        form_id: [eeww_work_info_form.id, eeprofile_work_info_form.id]
      },
      %{
        slug: "vehicle-allowance-eligible",
        type: :boolean,
        optional: true,
        source_table: "users",
        source_table_field: "country_specific_fields.vehicle_allowance_eligible",
        config: %{label: "Eligible for Vehicle Allowance", order: 3},
        country: south_korea,
        form_id: [eeww_work_info_form.id, eeprofile_work_info_form.id]
      },
      %{
        slug: "childcare-allowance-eligible",
        type: :boolean,
        optional: true,
        source_table: "users",
        source_table_field: "country_specific_fields.childcare_allowance_eligible",
        config: %{label: "Eligible for Childcare Allowance", order: 4},
        country: south_korea,
        form_id: [eeww_work_info_form.id, eeprofile_work_info_form.id]
      },
      %{
        slug: "resident-registration-number",
        type: :text,
        optional: true,
        source_table: "users",
        source_table_field: "country_specific_fields.resident_registration_number",
        config: %{label: "Resident Registration Number", order: 5},
        country: south_korea,
        form_id: [eeww_work_info_form.id, eeprofile_work_info_form.id]
      },
      %{
        slug: "resident-registration-address",
        type: :text,
        optional: true,
        source_table: "users",
        source_table_field: "country_specific_fields.resident_registration_address",
        config: %{label: "Address on Resident Registration Card", order: 6},
        country: south_korea,
        form_id: [eeww_work_info_form.id, eeprofile_work_info_form.id]
      },
      %{
        slug: "joining-date",
        type: :date,
        optional: true,
        source_table: "users",
        source_table_field: "country_specific_fields.joining_date",
        config: %{label: "Joining Date", order: 7},
        country: south_korea,
        form_id: [eeww_work_info_form.id, eeprofile_work_info_form.id]
      },
      %{
        slug: "designation",
        type: :text,
        optional: true,
        source_table: "users",
        source_table_field: "country_specific_fields.designation",
        config: %{label: "Designation", order: 8},
        country: south_korea,
        form_id: [eeww_work_info_form.id, eeprofile_work_info_form.id]
      },
      #
      # United Arab Emirates
      #
      %{
        slug: "preferred-languages",
        type: :text,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.preferred_languages",
        config: %{label: "Preferred Language(s)", order: 1},
        country: uae,
        form_id: eeww_other_info_form.id
      },
      %{
        slug: "mothers-name",
        type: :text,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.mothers_name",
        config: %{label: "Mother's Name", order: 3},
        country: uae,
        form_id: eeww_other_info_form.id
      },
      %{
        slug: "visa-status",
        type: :text,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.visa_status",
        config: %{label: "Current Visa Status", order: 4},
        country: uae,
        form_id: eeww_other_info_form.id
      },
      %{
        slug: "passport-type",
        type: :text,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.passport_type",
        config: %{label: "Passport Type", order: 1},
        country: uae,
        form_id: eeww_identification_info_form.id
      },
      %{
        slug: "home-country-address-line-1",
        type: :address,
        optional: false,
        source_table: "addresses",
        source_table_field: "line_1",
        config: %{
          foreign_key_path: "users.country_specific_fields.home_country_address_id",
          label: "Home Country Residential Address",
          order: 2
        },
        country: uae,
        form_id: [eeww_personal_info_form.id, eeprofile_personal_info_form.id]
      },
      %{
        slug: "home-country-address-line-2",
        type: :address,
        optional: true,
        source_table: "addresses",
        source_table_field: "line_2",
        config: %{
          foreign_key_path: "users.country_specific_fields.home_country_address_id",
          label: "Home Country Residential Address",
          order: 2
        },
        country: uae,
        form_id: [eeww_personal_info_form.id, eeprofile_personal_info_form.id]
      },
      %{
        slug: "home-country-address-line-3",
        type: :address,
        optional: true,
        source_table: "addresses",
        source_table_field: "line_3",
        config: %{
          foreign_key_path: "users.country_specific_fields.home_country_address_id",
          label: "Home Country Residential Address",
          order: 2
        },
        country: uae,
        form_id: [eeww_personal_info_form.id, eeprofile_personal_info_form.id]
      },
      %{
        slug: "home-country-address-city",
        type: :address,
        optional: false,
        source_table: "addresses",
        source_table_field: "city",
        config: %{
          foreign_key_path: "users.country_specific_fields.home_country_address_id",
          label: "Home Country Residential Address",
          order: 2
        },
        country: uae,
        form_id: [eeww_personal_info_form.id, eeprofile_personal_info_form.id]
      },
      %{
        slug: "home-country-address-postal-code",
        type: :address,
        optional: false,
        source_table: "addresses",
        source_table_field: "postal_code",
        config: %{
          foreign_key_path: "users.country_specific_fields.home_country_address_id",
          label: "Home Country Residential Address",
          order: 2
        },
        country: uae,
        form_id: [eeww_personal_info_form.id, eeprofile_personal_info_form.id]
      },
      %{
        slug: "home-country-address-county-district",
        type: :address,
        optional: true,
        source_table: "addresses",
        source_table_field: "county_district",
        config: %{
          foreign_key_path: "users.country_specific_fields.home_country_address_id",
          label: "Home Country Residential Address",
          order: 2
        },
        country: uae,
        form_id: [eeww_personal_info_form.id, eeprofile_personal_info_form.id]
      },
      %{
        slug: "home-country-address-state-province",
        type: :address,
        source_table: "addresses",
        optional: false,
        source_table_field: "state_province",
        config: %{
          foreign_key_path: "users.country_specific_fields.home_country_address_id",
          label: "Home Country Residential Address",
          order: 2
        },
        country: uae,
        form_id: [eeww_personal_info_form.id, eeprofile_personal_info_form.id]
      },
      %{
        slug: "home-country-address-state-province-iso-alpha-2-code",
        type: :address,
        source_table: "addresses",
        optional: false,
        source_table_field: "state_province_iso_alpha_2_code",
        config: %{
          foreign_key_path: "users.country_specific_fields.home_country_address_id",
          label: "Home Country Residential Address",
          order: 2
        },
        country: uae,
        form_id: [eeww_personal_info_form.id, eeprofile_personal_info_form.id]
      },
      %{
        slug: "home-country-address-country-id",
        type: :address,
        source_table: "addresses",
        optional: false,
        source_table_field: "country_id",
        config: %{
          foreign_key_path: "users.country_specific_fields.home_country_address_id",
          label: "Home Country Residential Address",
          order: 2,
          type_override: "id"
        },
        country: uae,
        form_id: [eeww_personal_info_form.id, eeprofile_personal_info_form.id]
      },
      %{
        slug: "home-country-address-formatted-address",
        type: :address,
        source_table: "addresses",
        optional: false,
        source_table_field: "formatted_address",
        config: %{
          foreign_key_path: "users.country_specific_fields.home_country_address_id",
          label: "Home Country Residential Address",
          order: 2
        },
        country: uae,
        form_id: [eeww_personal_info_form.id, eeprofile_personal_info_form.id]
      },
      %{
        slug: "uae-address-line-1",
        type: :address,
        optional: false,
        source_table: "addresses",
        source_table_field: "line_1",
        config: %{
          foreign_key_path: "users.country_specific_fields.uae_address_id",
          label: "UAE Address",
          order: 3
        },
        country: uae,
        form_id: [eeww_personal_info_form.id, eeprofile_personal_info_form.id]
      },
      %{
        slug: "uae-address-line-2",
        type: :address,
        optional: true,
        source_table: "addresses",
        source_table_field: "line_2",
        config: %{
          foreign_key_path: "users.country_specific_fields.uae_address_id",
          label: "UAE Address",
          order: 3
        },
        country: uae,
        form_id: [eeww_personal_info_form.id, eeprofile_personal_info_form.id]
      },
      %{
        slug: "uae-address-line-3",
        type: :address,
        optional: true,
        source_table: "addresses",
        source_table_field: "line_3",
        config: %{
          foreign_key_path: "users.country_specific_fields.uae_address_id",
          label: "UAE Address",
          order: 3
        },
        country: uae,
        form_id: [eeww_personal_info_form.id, eeprofile_personal_info_form.id]
      },
      %{
        slug: "uae-address-city",
        type: :address,
        optional: false,
        source_table: "addresses",
        source_table_field: "city",
        config: %{
          foreign_key_path: "users.country_specific_fields.uae_address_id",
          label: "UAE Address",
          order: 3
        },
        country: uae,
        form_id: [eeww_personal_info_form.id, eeprofile_personal_info_form.id]
      },
      %{
        slug: "uae-address-postal-code",
        type: :address,
        optional: false,
        source_table: "addresses",
        source_table_field: "postal_code",
        config: %{
          foreign_key_path: "users.country_specific_fields.uae_address_id",
          label: "UAE Address",
          order: 3
        },
        country: uae,
        form_id: [eeww_personal_info_form.id, eeprofile_personal_info_form.id]
      },
      %{
        slug: "uae-address-county-district",
        type: :address,
        optional: true,
        source_table: "addresses",
        source_table_field: "county_district",
        config: %{
          foreign_key_path: "users.country_specific_fields.uae_address_id",
          label: "UAE Address",
          order: 3
        },
        country: uae,
        form_id: [eeww_personal_info_form.id, eeprofile_personal_info_form.id]
      },
      %{
        slug: "uae-address-state-province",
        type: :address,
        source_table: "addresses",
        optional: false,
        source_table_field: "state_province",
        config: %{
          foreign_key_path: "users.country_specific_fields.uae_address_id",
          label: "UAE Address",
          order: 3
        },
        country: uae,
        form_id: [eeww_personal_info_form.id, eeprofile_personal_info_form.id]
      },
      %{
        slug: "uae-address-state-province-iso-alpha-2-code",
        type: :address,
        source_table: "addresses",
        optional: false,
        source_table_field: "state_province_iso_alpha_2_code",
        config: %{
          foreign_key_path: "users.country_specific_fields.uae_address_id",
          label: "UAE Address",
          order: 3
        },
        country: uae,
        form_id: [eeww_personal_info_form.id, eeprofile_personal_info_form.id]
      },
      %{
        slug: "uae-address-country-id",
        type: :address,
        source_table: "addresses",
        optional: false,
        source_table_field: "country_id",
        config: %{
          foreign_key_path: "users.country_specific_fields.uae_address_id",
          label: "UAE Address",
          order: 3,
          type_override: "id"
        },
        country: uae,
        form_id: [eeww_personal_info_form.id, eeprofile_personal_info_form.id]
      },
      %{
        slug: "uae-address-formatted-address",
        type: :address,
        source_table: "addresses",
        optional: false,
        source_table_field: "formatted_address",
        config: %{
          foreign_key_path: "users.country_specific_fields.uae_address_id",
          label: "UAE Address",
          order: 3
        },
        country: uae,
        form_id: [eeww_personal_info_form.id, eeprofile_personal_info_form.id]
      },
      %{
        slug: "highest-qualification",
        type: :text,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.highest_qualification",
        config: %{label: "Highest Qualification", order: 4},
        country: uae,
        form_id: [eeww_personal_info_form.id, eeprofile_personal_info_form.id]
      },
      %{
        slug: "highest-qualification-subject",
        type: :text,
        optional: false,
        source_table: "users",
        source_table_field: "country_specific_fields.highest_qualification_subject",
        config: %{label: "Subject Name of Highest Qualification", order: 5},
        country: uae,
        form_id: [eeww_personal_info_form.id, eeprofile_personal_info_form.id]
      },
      %{
        slug: "number-dependents",
        type: :number,
        optional: true,
        source_table: "users",
        source_table_field: "country_specific_fields.number_dependents",
        config: %{label: "Number of Dependents", order: 6},
        country: uae,
        form_id: [eeww_personal_info_form.id, eeprofile_personal_info_form.id]
      },
      %{
        slug: "dependent-1-visa-file-number",
        type: :text,
        optional: true,
        source_table: "users",
        source_table_field: "country_specific_fields.dependent_1_visa_file_number",
        config: %{label: "Dependent 1 UAE Visa File Number", order: 12},
        country: uae,
        form_id: [eeww_personal_info_form.id, eeprofile_personal_info_form.id]
      },
      %{
        slug: "dependent-1-uid",
        type: :text,
        optional: true,
        source_table: "users",
        source_table_field: "country_specific_fields.dependent_1_uid",
        config: %{label: "Dependent 1 UID Number", order: 13},
        country: uae,
        form_id: [eeww_personal_info_form.id, eeprofile_personal_info_form.id]
      },
      %{
        slug: "dependent-1-visa-expiry-date",
        type: :date,
        optional: true,
        source_table: "users",
        source_table_field: "country_specific_fields.dependent_1_visa_expiry_date",
        config: %{label: "Dependent 1 UAE Visa Expiry Date", order: 14},
        country: uae,
        form_id: [eeww_personal_info_form.id, eeprofile_personal_info_form.id]
      },
      %{
        slug: "dependent-1-emirates-id",
        type: :text,
        optional: true,
        source_table: "users",
        source_table_field: "country_specific_fields.dependent_1_emirates_id",
        config: %{label: "Dependent 1 Emirates ID Number", order: 15},
        country: uae,
        form_id: [eeww_personal_info_form.id, eeprofile_personal_info_form.id]
      },
      %{
        slug: "dependent-2-visa-file-number",
        type: :text,
        optional: true,
        source_table: "users",
        source_table_field: "country_specific_fields.dependent_2_visa_file_number",
        config: %{label: "Dependent 2 UAE Visa File Number", order: 21},
        country: uae,
        form_id: [eeww_personal_info_form.id, eeprofile_personal_info_form.id]
      },
      %{
        slug: "dependent-2-uid",
        type: :text,
        optional: true,
        source_table: "users",
        source_table_field: "country_specific_fields.dependent_2_uid",
        config: %{label: "Dependent 2 UID Number", order: 22},
        country: uae,
        form_id: [eeww_personal_info_form.id, eeprofile_personal_info_form.id]
      },
      %{
        slug: "dependent-2-visa-expiry-date",
        type: :date,
        optional: true,
        source_table: "users",
        source_table_field: "country_specific_fields.dependent_2_visa_expiry_date",
        config: %{label: "Dependent 2 UAE Visa Expiry Date", order: 23},
        country: uae,
        form_id: [eeww_personal_info_form.id, eeprofile_personal_info_form.id]
      },
      %{
        slug: "dependent-2-emirates-id",
        type: :text,
        optional: true,
        source_table: "users",
        source_table_field: "country_specific_fields.dependent_2_emirates_id",
        config: %{label: "Dependent 2 Emirates ID Number", order: 24},
        country: uae,
        form_id: [eeww_personal_info_form.id, eeprofile_personal_info_form.id]
      },
      %{
        slug: "dependent-3-visa-file-number",
        type: :text,
        optional: true,
        source_table: "users",
        source_table_field: "country_specific_fields.dependent_3_visa_file_number",
        config: %{label: "Dependent 3 UAE Visa File Number", order: 30},
        country: uae,
        form_id: [eeww_personal_info_form.id, eeprofile_personal_info_form.id]
      },
      %{
        slug: "dependent-3-uid",
        type: :text,
        optional: true,
        source_table: "users",
        source_table_field: "country_specific_fields.dependent_3_uid",
        config: %{label: "Dependent 3 UID Number", order: 31},
        country: uae,
        form_id: [eeww_personal_info_form.id, eeprofile_personal_info_form.id]
      },
      %{
        slug: "dependent-3-visa-expiry-date",
        type: :date,
        optional: true,
        source_table: "users",
        source_table_field: "country_specific_fields.dependent_3_visa_expiry_date",
        config: %{label: "Dependent 3 UAE Visa Expiry Date", order: 32},
        country: uae,
        form_id: [eeww_personal_info_form.id, eeprofile_personal_info_form.id]
      },
      %{
        slug: "dependent-3-emirates-id",
        type: :text,
        optional: true,
        source_table: "users",
        source_table_field: "country_specific_fields.dependent_3_emirates_id",
        config: %{label: "Dependent 3 Emirates ID Number", order: 33},
        country: uae,
        form_id: [eeww_personal_info_form.id, eeprofile_personal_info_form.id]
      },
      %{
        slug: "dependent-4-visa-file-number",
        type: :text,
        optional: true,
        source_table: "users",
        source_table_field: "country_specific_fields.dependent_4_visa_file_number",
        config: %{label: "Dependent 4 UAE Visa File Number", order: 39},
        country: uae,
        form_id: [eeww_personal_info_form.id, eeprofile_personal_info_form.id]
      },
      %{
        slug: "dependent-4-uid",
        type: :text,
        optional: true,
        source_table: "users",
        source_table_field: "country_specific_fields.dependent_4_uid",
        config: %{label: "Dependent 4 UID Number", order: 40},
        country: uae,
        form_id: [eeww_personal_info_form.id, eeprofile_personal_info_form.id]
      },
      %{
        slug: "dependent-4-visa-expiry-date",
        type: :date,
        optional: true,
        source_table: "users",
        source_table_field: "country_specific_fields.dependent_4_visa_expiry_date",
        config: %{label: "Dependent 4 UAE Visa Expiry Date", order: 41},
        country: uae,
        form_id: [eeww_personal_info_form.id, eeprofile_personal_info_form.id]
      },
      %{
        slug: "dependent-4-emirates-id",
        type: :text,
        optional: true,
        source_table: "users",
        source_table_field: "country_specific_fields.dependent_4_emirates_id",
        config: %{label: "Dependent 4 Emirates ID Number", order: 42},
        country: uae,
        form_id: [eeww_personal_info_form.id, eeprofile_personal_info_form.id]
      }
    ]

    eeww_csf_params =
      Enum.map(country_specific_fields_map, fn form_field ->
        %{
          slug: form_field.slug,
          type: form_field.type,
          optional: form_field.optional,
          source_table: form_field.source_table,
          source_table_field: form_field.source_table_field,
          config: Map.get(form_field.config, :base) || %{},
          inserted_at: inserted_and_updated_at,
          updated_at: inserted_and_updated_at
        }
      end)

    {_num, form_fields} =
      Repo.insert_all(FormField, eeww_csf_params,
        on_conflict: {:replace_all_except, [:slug, :id, :inserted_at]},
        conflict_target: :slug,
        returning: true
      )

    # No country overrides on this form
    eeww_csf_form_form_field_params =
      Enum.reduce(form_fields, [], fn form_field, acc ->
        form_field_data =
          Enum.find(country_specific_fields_map, fn field_data ->
            field_data.slug == form_field.slug
          end)

        fields_split_by_country =
          if is_list(form_field_data.country) do
            # field shared across multiple countries
            Enum.map(form_field_data.country, fn country ->
              %{
                form_id: form_field_data.form_id,
                form_field_id: form_field.id,
                country_id: country.id,
                config_override:
                  Map.get(form_field_data.config, String.to_atom(country.iso_alpha_2_code)),
                source_table_field_override:
                  "#{form_field_data.source_table_field}.#{country.iso_alpha_2_code}",
                inserted_at: inserted_and_updated_at,
                updated_at: inserted_and_updated_at
              }
            end)
          else
            # field used by only one country
            [
              %{
                form_id: form_field_data.form_id,
                form_field_id: form_field.id,
                country_id: form_field_data.country.id,
                config_override: form_field_data.config || %{},
                source_table_field_override: nil,
                inserted_at: inserted_and_updated_at,
                updated_at: inserted_and_updated_at
              }
            ]
          end

        # Now split up further for fields that are shared across forms
        form_field_params =
          Enum.reduce(fields_split_by_country, [], fn country_field, ff_acc ->
            split_fields =
              if is_list(country_field.form_id) do
                # field shared across multiple forms
                Enum.map(country_field.form_id, fn form_id ->
                  %{
                    form_id: form_id,
                    form_field_id: country_field.form_field_id,
                    country_id: country_field.country_id,
                    config_override: country_field.config_override,
                    source_table_field_override: country_field.source_table_field_override,
                    inserted_at: inserted_and_updated_at,
                    updated_at: inserted_and_updated_at
                  }
                end)
              else
                # field used by only one form
                [country_field]
              end

            ff_acc ++ split_fields
          end)

        acc ++ form_field_params
      end)

    # Can't insert_all because country_id (part of unique index) may be nil
    Enum.each(eeww_csf_form_form_field_params, fn form_field_params ->
      existing_form_form_field =
        Repo.one(
          from f in FormFormField,
            where:
              f.form_id == ^form_field_params.form_id and
                f.form_field_id == ^form_field_params.form_field_id and
                f.country_id == ^form_field_params.country_id
        )

      if is_nil(existing_form_form_field) do
        changeset = FormFormField.changeset(%FormFormField{}, form_field_params)
        Repo.insert!(changeset)
      else
        changeset = FormFormField.changeset(existing_form_form_field, form_field_params)
        Repo.update!(changeset)
      end
    end)
  end
end
