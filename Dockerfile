FROM golang:alpine AS chihaya-build-env
RUN apk add --no-cache ca-certificates curl git 
WORKDIR /go/src/github.com/chihaya
RUN git clone https://github.com/chihaya/chihaya.git
WORKDIR /go/src/github.com/chihaya/chihaya
RUN go get -u github.com/golang/dep/...
RUN dep ensure
RUN CGO_ENABLED=0 go install github.com/chihaya/chihaya/cmd/...

FROM node:alpine
RUN apk add --no-cache ca-certificates nginx tini aria2 \
    && npm install -g create-torrent
COPY --from=chihaya-build-env /go/bin/chihaya /bin/chihaya
COPY serve /bin/serve
COPY get /bin/get
COPY nginx_vhost.conf /etc/nginx/conf.d/default.conf
COPY chihaya.yaml /etc/chihaya.yaml
RUN mkdir -p /data /usr/share/nginx/html \
    && adduser -D chihaya

EXPOSE 80 443

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/bin/serve"]
