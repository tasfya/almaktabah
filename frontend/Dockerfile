FROM node:18

WORKDIR /app
COPY ./frontend ./

RUN npm install
RUN npm run build

EXPOSE 3000
CMD ["npm", "start"]
