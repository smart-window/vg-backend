# Velocity

## Running the Project

### Docker

If this is your first time starting the API, you will also need to create/seed a local database:

- `docker-compose run web mix ecto.setup`

- `docker-compose up`

### Local Elixir Deps

Install ASDF and add elixir plugin:

- https://asdf-vm.com/#/core-manage-asdf-vm
- `asdf plugin add erlang`
- `asdf plugin add elixir`

Run these commands to get the dependencies set up:

- `asdf install`
- `docker-compose up -d db`
- `mix deps.get`

If this is your first time starting the API, you will also need to create/seed a local database:

- `mix ecto.setup`

install and start redis (caching engine):
- `brew install redis`
- `brew services start redis`

Start the phoenix server:

- `mix phx.server`
