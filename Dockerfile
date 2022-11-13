FROM alpine:latest

RUN apk add tini bash ucarp docker-cli

COPY --chmod=755 *sh /

ENTRYPOINT ["tini", "/docker-entrypoint.sh"]
