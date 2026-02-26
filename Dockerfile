# Stage 1: Build Rust NIF
FROM rust:1.83-bookworm AS nif-builder

RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*

# Clone labs crates (NIF dependencies)
ARG LABS_REF=main
RUN git clone --depth 1 --branch ${LABS_REF} https://github.com/cyanea-io/labs.git /build/labs

# Copy NIF source
COPY native/cyanea_native /build/cyanea/native/cyanea_native

# Rewrite path deps to absolute paths inside the container
RUN sed -i 's|path = "../../../labs/|path = "/build/labs/|g' \
    /build/cyanea/native/cyanea_native/Cargo.toml

WORKDIR /build/cyanea/native/cyanea_native
RUN cargo build --release

# Stage 2: Build Elixir release
FROM hexpm/elixir:1.17.3-erlang-27.2-debian-bookworm-20241202 AS elixir-builder

RUN apt-get update && apt-get install -y build-essential git && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install hex and rebar
RUN mix local.hex --force && mix local.rebar --force

ENV MIX_ENV=prod

# Install dependencies first (cache layer)
COPY mix.exs mix.lock ./
RUN mix deps.get --only $MIX_ENV
RUN mkdir config
COPY config/config.exs config/${MIX_ENV}.exs config/
RUN mix deps.compile

# Copy compiled NIF from rust stage
COPY --from=nif-builder /build/cyanea/native/cyanea_native/target/release/libcyanea_native.so \
    priv/native/libcyanea_native.so

# Build assets
COPY assets assets
COPY priv priv
RUN mix assets.deploy

# Compile application
COPY lib lib
COPY native native
RUN mix compile

# Build release
COPY config/runtime.exs config/
RUN mix release

# Stage 3: Minimal runtime
FROM debian:bookworm-slim AS runtime

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        libstdc++6 openssl libncurses5 locales ca-certificates libsqlite3-0 && \
    rm -rf /var/lib/apt/lists/*

RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

WORKDIR /app

RUN useradd --create-home app
COPY --from=elixir-builder --chown=app:app /app/_build/prod/rel/cyanea ./
USER app

CMD ["bin/server"]
