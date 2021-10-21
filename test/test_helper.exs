{:ok, _} = Application.ensure_all_started(:ex_machina)
ExUnit.start()
Faker.start()
Ecto.Adapters.SQL.Sandbox.mode(Velocity.Repo, :manual)

Exq.Mock.start_link(mode: :redis)

Mox.defmock(Velocity.Clients.MockOkta, for: Velocity.Clients.Okta)
Application.put_env(:velocity, :okta_client, Velocity.Clients.MockOkta)

Mox.defmock(MockExq, for: Velocity.Exq)
Application.put_env(:velocity, :exq, MockExq)

Mox.defmock(Velocity.Clients.MockPegaBasic, for: Velocity.Clients.PegaBasic)
Application.put_env(:velocity, :pega_client, Velocity.Clients.MockPegaBasic)

Mox.defmock(Velocity.Clients.MockHelpjuice, for: Velocity.Clients.Helpjuice)
Application.put_env(:velocity, :helpjuice_client, Velocity.Clients.MockHelpjuice)
