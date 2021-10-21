# https://hexdocs.pm/phoenix/releases.html

FROM elixir:1.11.3-alpine AS build

RUN mkdir /app
COPY . /app
WORKDIR /app

RUN mix local.hex --force && \
  mix local.rebar --force

ENV MIX_ENV=dev
ENV POSTGRES_USER=postgres
ENV POSTGRES_PASSWORD=postgres
ENV POSTGRES_HOST=db

RUN mix deps.get
RUN mix do compile

CMD ["mix", "phx.server"]