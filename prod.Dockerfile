FROM elixir:1.10 AS build

RUN curl -sL https://deb.nodesource.com/setup_12.x | bash -

RUN apt-get update && apt-get install -y gcc g++ make nodejs git python curl software-properties-common && rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN mix local.hex --force && \
    mix local.rebar --force

ENV MIX_ENV=prod

COPY mix.exs mix.lock ./
COPY config config
RUN mix do deps.get, deps.compile

COPY assets/package.json assets/package-lock.json ./assets/
RUN npm --prefix ./assets ci --progress=false --no-audit --loglevel=error

COPY priv priv
COPY assets assets
RUN npm run --prefix ./assets deploy
RUN mix phx.digest

COPY lib lib

# uncomment COPY if rel/ exists
# COPY rel rel

RUN mix do compile, release

FROM elixir:1.10 AS app
RUN apt-get update && \
    apt-get install -y bash libz-dev openssl ncurses-base postgresql-client-11 && \
    rm -rf /var/lib/apt/lists/*


WORKDIR /app

COPY --from=build /app/_build/prod/rel/pjeski ./
COPY entrypoint.sh ./

ENV HOME=/app
CMD bash entrypoint.sh
