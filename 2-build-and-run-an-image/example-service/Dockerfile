FROM node:18 AS build-base
WORKDIR /app
COPY package*.json ./

FROM build-base AS install-prod-dependencies
RUN npm ci --omit dev

FROM build-base AS build
RUN npm ci
COPY tsconfig.json src/ ./
RUN npm run build

FROM gcr.io/distroless/nodejs18-debian11
WORKDIR /app
COPY package*.json ./
COPY --from=install-prod-dependencies --chown=node /app/node_modules/ ./node_modules/
COPY --from=build --chown=node /app/dist/ ./dist/
USER 1000
CMD ["./dist/app.js"]
