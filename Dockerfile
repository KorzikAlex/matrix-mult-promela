FROM debian:13.4-slim AS base

ENV DEBIAN_FRONTEND=noninteractive
WORKDIR /app

FROM base AS deps

RUN apt-get update && apt-get install -y --no-install-recommends \
    spin \
    gcc
    
RUN rm -rf /var/lib/apt/lists/*

FROM deps AS runtime

COPY ./src .

CMD ["spin", "main.pml"]
