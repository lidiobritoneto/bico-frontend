# ---------- BUILD ----------
FROM ghcr.io/cirruslabs/flutter:stable AS build
WORKDIR /app

COPY . .

RUN flutter pub get
RUN flutter build web --release

# ---------- RUN ----------
FROM node:20-alpine
WORKDIR /app
RUN npm i -g serve
COPY --from=build /app/build/web ./build/web

EXPOSE 10000
CMD ["serve", "-s", "build/web", "-l", "10000"]