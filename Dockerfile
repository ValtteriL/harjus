FROM gcr.io/distroless/static-debian12

WORKDIR /app

COPY _build/dev/rel/harjus ./

ENTRYPOINT ["./harjus/bin/harjus start"]
