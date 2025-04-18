# ✅ Base image
FROM node:18-alpine

# ✅ Set working directory
WORKDIR /app

# ✅ Copy package.json and package-lock.json (if available) to install dependencies
COPY package*.json ./

# ✅ Install dependencies (production only for production environment)
RUN npm install --production

# ✅ Copy the rest of the app (excluding files in .dockerignore)
COPY . .

# ✅ Expose Strapi port
EXPOSE 1337

# ✅ Build the app (optional: use if you're customizing admin panel)
# RUN npm run build

# ✅ Run Strapi in production mode (for production environment)
CMD ["npm", "run", "start"]

