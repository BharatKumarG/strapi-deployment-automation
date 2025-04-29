# Stage 1 - Build with necessary tools
FROM node:14-alpine AS builder
WORKDIR /app

# Install build dependencies
RUN apk add --no-cache python3 make g++

# Copy package files first
COPY package*..json ./
COPY tsconfig.json ./

# Install dependencies
RUN npm install --production

# Copy source files
COPY . .

# Build project
RUN npm run build

# Stage 2 - Minimal production image
FROM node:14-alpine
WORKDIR /app

# Copy production files
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/config ./config
COPY --from=builder /app/public ./public

# ✅ Minimal required change: expose to ECS
ENV HOST=0.0.0.0

# Install runtime dependencies
RUN apk add --no-cache sqlite && \
    mkdir -p /app/.tmp && \
    chown -R node:node /app

USER node
EXPOSE 1337
CMD ["npm", "start"]
