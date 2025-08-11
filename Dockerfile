FROM node:16-alpine
WORKDIR /app
COPY server.js .
EXPOSE 8081
CMD ["node", "server.js"]
