# Imagen base
FROM node:18

# Carpeta de trabajo
WORKDIR /app

# Copiar archivos
COPY package*.json ./

# Instalar dependencias
RUN npm install

# Copiar todo
COPY . .

# Compilar (NestJS)
RUN npm run build

# Exponer puerto
EXPOSE 3000

# Ejecutar app
CMD ["node", "dist/main"]
