FROM alpine:latest

RUN apk add --no-cache bash curl jq

WORKDIR /app

COPY godaddy-cname.sh .
COPY .example.env .

RUN chmod +x godaddy-cname.sh && \
    sed -i 's/\r$//' godaddy-cname.sh

ENTRYPOINT ["/app/godaddy-cname.sh"]
