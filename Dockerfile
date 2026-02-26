# ---------- STAGE 1: BUILD FLUTTER WEB ----------
FROM debian:bookworm-slim AS build

RUN apt-get update && apt-get install -y \
  git curl unzip xz-utils ca-certificates \
  && rm -rf /var/lib/apt/lists/*

# Flutter (stable)
RUN git clone https://github.com/flutter/flutter.git /flutter
ENV PATH="/flutter/bin:/flutter/bin/cache/dart-sdk/bin:${PATH}"

RUN flutter --version
RUN flutter config --enable-web

WORKDIR /app
COPY . .

RUN flutter pub get
RUN flutter build web --release

# ---------- STAGE 2: SERVE STATIC FILES ----------
FROM node:20-alpine AS runner
WORKDIR /app

# copia o build do flutter
COPY --from=build /app/build/web ./build/web

# 'serve' pra servir SPA e respeitar $PORT do Render
RUN npm i -g serve

ENV PORT=10000
EXPOSE 10000

CMD serve build/web -l 10000 --single