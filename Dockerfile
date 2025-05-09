
# ---- Base Node.js image for building ----
# Use a specific version tag for reproducibility, matching your devenv.nix (Node 20)
# Alpine is used for a smaller image size.
FROM node:22-alpine AS base
WORKDIR /usr/src/app

# Install pnpm globally
# Check https://pnpm.io/installation#docker for the latest recommended way
RUN npm install -g pnpm

# ---- Dependencies Stage ----
# This stage installs dependencies and caches them.
FROM base AS deps
# Copy only package.json and pnpm-lock.yaml to leverage Docker cache.
# If these files don't change, this layer and the pnpm install layer will be cached.
COPY package.json pnpm-lock.yaml ./

# Install only production dependencies.
# If you have a build step (e.g., TypeScript compilation, bundling) that requires devDependencies,
# you would run `pnpm install --frozen-lockfile` here, then your build command,
# and then `pnpm prune --prod` before copying to the next stage.
# For a simple `node app.js`, `--prod` is usually sufficient.
RUN pnpm install --prod --frozen-lockfile

# ---- Builder Stage (if you have a build step like TypeScript, Webpack, etc.) ----
# If your app.js is plain JavaScript and needs no build step, you can skip this
# and copy source code directly in the 'release' stage.
# If you DO have a build step:
# FROM deps AS builder
# COPY . .
# RUN pnpm run build # Assuming you have a "build" script in package.json

# ---- Release Stage ----
# This is the final, lean image.
FROM node:22-alpine AS release
WORKDIR /usr/src/app

# Set NODE_ENV to production
ENV NODE_ENV=production

# Create a non-root user and group
# The official node images already provide a 'node' user (UID 1000, GID 1000)
# We will use that user.
# If it didn't, you'd do:
# RUN addgroup -S appgroup && adduser -S appuser -G appgroup
# USER appuser

# Copy dependencies from the 'deps' stage
COPY --from=deps --chown=node:node /usr/src/app/node_modules ./node_modules
# Copy package.json (some libraries might need it at runtime, and it's small)
COPY --from=deps --chown=node:node /usr/src/app/package.json ./package.json

# Copy application code
# If you had a 'builder' stage with a dist/ folder:
# COPY --from=builder --chown=node:node /usr/src/app/dist ./dist
# COPY --from=builder --chown=node:node /usr/src/app/app.js ./app.js # or whatever your entrypoint is
# For a simple app without a build step:
COPY --chown=node:node app.js ./app.js
# If you have other assets or config files needed at runtime, copy them too:
# COPY --chown=node:node public ./public
# COPY --chown=node:node config ./config

# Switch to the non-root user
USER node

# Expose the port the app runs on (from your docker-run-local script)
EXPOSE 8080

# Healthcheck (optional, but good practice)
# Adjust the CMD if your app has a specific health endpoint (e.g., /healthz)
# This assumes your app responds with a 2xx or 3xx on its root path.
# HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
#   CMD wget -q --spider http://localhost:8080/ || exit 1
# If using curl (often available on alpine):
# HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
#   CMD curl -f http://localhost:8080/ || exit 1
# For now, I'll comment it out as it depends on your app.js behavior.

# Command to run the application (from your processes.app and docker-run-local)
CMD ["node", "app.js"]
