FROM node:22-alpine

WORKDIR /app

RUN apk add --no-cache curl

COPY package.json .

RUN npm install

COPY . .

RUN adduser -D -u 1001 appuser && \
    chown -R appuser:appuser /app && \
    chmod -R 700 /app

USER appuser

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=5 \
  CMD curl -f http://localhost:4000/ || exit 1

EXPOSE 4000

CMD ["npm", "start"]
