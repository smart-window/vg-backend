defmodule Velocity.Contexts.EmailTemplatesTest do
  use Velocity.DataCase, async: true

  alias Velocity.Contexts.EmailTemplates

  describe "EmailTemplates.list_templates/0" do
    test "it returns all email templates" do
      Factory.insert_list(3, :email_template)

      assert Enum.count(EmailTemplates.list_templates()) == 3
    end
  end

  describe "EmailTemplates.get_template/3" do
    test "it brings in the html sections without a country" do
      email_template = Factory.insert(:email_template)
      Factory.insert(:html_section, email_template: email_template, country: nil)

      template = EmailTemplates.get_template(email_template.id)
      assert Enum.all?(template.html_sections, &is_nil(&1.country_id))
    end

    test "it brings in related html sections with a country specified" do
      email_template = Factory.insert(:email_template, html_sections: [])
      country = Factory.insert(:country)
      Factory.insert(:html_section, email_template: email_template, country: country)

      template = EmailTemplates.get_template(email_template.id, country.id)

      assert Enum.all?(
               template.html_sections,
               fn section ->
                 is_nil(section.country_id) or section.country_id == country.id
               end
             )
    end

    test "it interpolates given variables into the template" do
      email_template = Factory.insert(:email_template, html_sections: [])

      section =
        Factory.insert(:html_section,
          email_template: email_template,
          html: "<div>Hello, {{first_name}}. From: {{me}}</div>"
        )

      html =
        email_template.id
        |> EmailTemplates.get_template(section.country_id, %{
          first_name: "bobby",
          me: "taylor"
        })
        |> Map.get(:html_sections)
        |> List.first()
        |> Map.get(:html)

      assert String.contains?(html, "bobby")
      assert String.contains?(html, "taylor")
    end
  end
end
