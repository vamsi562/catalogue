FROM node:20-alpine3.22 AS builder
WORKDIR /opt/server
COPY package.json .
COPY *.js .
RUN npm install


FROM node:20-alpine3.22
WORKDIR /opt/server
EXPOSE 8080
RUN addgroup -S roboshop && adduser -S roboshop -G roboshop
COPY --from=builder --chown=roboshop:roboshop /opt/server/ /opt/server/
LABEL project="roboshop" \
    maintainer="vamsi" \
    component="catalogue"
ENV MONGO=true \
    MONGO_URL="mongodb://mongodb:27017/catalogue"
USER roboshop
CMD [ "server.js" ]
ENTRYPOINT [ "node" ]


# FROM node:20
# WORKDIR /opt/server
# COPY package.json .
# COPY *.js .
# RUN npm install
# ENV MONGO=true \
#     MONGO_URL="mongodb://mongo:27017/catalogue"
# CMD [ "node", "server.js" ]