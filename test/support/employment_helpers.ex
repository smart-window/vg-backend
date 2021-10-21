alias Velocity.Factory

defmodule Velocity.EmploymentHelpers do
  def setup_employment(user, country \\ nil) do
    client = Factory.insert(:client)
    partner = Factory.insert(:partner)

    employee =
      Factory.insert(:employee, %{
        user: user
      })

    job =
      Factory.insert(:job, %{
        client: client
      })

    contract =
      Factory.insert(:contract, %{
        client: client
      })

    country =
      if country != nil do
        country
      else
        Factory.insert(:country)
      end

    Factory.insert(:employment, %{
      partner: partner,
      employee: employee,
      job: job,
      contract: contract,
      country: country,
      effective_date: "2021-03-24"
    })
  end
end
