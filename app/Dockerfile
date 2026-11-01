FROM node:20-alpine
WORKDIR /usr/src/app

# Install production dependencies first (better layer caching)
COPY package*.json ./
RUN npm ci --omit=dev

COPY . .

# Run as the non-root user that ships with the node image
USER node
EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=3s --start-period=20s \
  CMD wget -qO- http://localhost:3000/health || exit 1

CMD ["node", "server.js"]
