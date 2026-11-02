# Сайт документации CherryPick: сборка Astro и раздача статики через nginx.
# Конфиг nginx — штатный из образа: страницы лежат папками с index.html.
#
#   docker buildx build --platform linux/amd64 \
#     -t harbor.openidealab.com/cherrypick/site:<короткий SHA> site/
#
# Тег — короткий SHA коммита, из которого собран образ (см. k8s/deployment.yaml).

FROM node:22-slim AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --no-audit --no-fund
COPY . .
RUN npm run build

FROM nginx:1.29-alpine
COPY --from=build /app/dist /usr/share/nginx/html
EXPOSE 80
