Line-by-Line Explanation
Stage 1: The Builder (Compiling the Code)
In this stage, we prepare the environment and build the application binary.

FROM golang:1.22-alpine AS builder

Starts with a Go 1.22 environment on a lightweight Linux (Alpine).

RUN apk add --no-cache git ca-certificates

Installs basic tools needed to fetch libraries and make secure connections.

WORKDIR /usr/src/app

Sets the "home" folder inside the container where the work happens.

COPY go.mod go.sum ./

Copies only the dependency lists first.

RUN go mod download

Downloads all required libraries. Docker caches this step to save time later.

COPY . .

Copies your actual source code (like main.go) into the container.

RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o product-catalog .

CGO_ENABLED=0: Makes the app "self-contained" so it doesn't need external C libraries.

-ldflags="-s -w": Shrinks the file size by removing extra "debug" data.

-o product-catalog: Names the finished program "product-catalog".

Stage 2: The Runner (The Final Image)
This is the only part that gets deployed to production.

FROM alpine:3.19

Starts a brand new, empty, and tiny Linux environment.

RUN addgroup -S appgroup && adduser -S appuser -G appgroup

Creates a "standard" user instead of using the "Admin" (root) user for safety.

USER appuser

Switches to that safe user.

WORKDIR /app

Sets the folder where the app will live.

COPY --from=builder /usr/src/app/product-catalog .

Reaches back into the Builder stage and grabs only the finished program.

COPY --from=builder /usr/src/app/products ./products

Copies the products.json data folder required for the catalog to load.

ENV PRODUCT_CATALOG_PORT=8088

Sets the default port the app will listen on.

EXPOSE 8088

Tells Docker to allow traffic through port 8088.

ENTRYPOINT ["./product-catalog"]

The command that starts your application immediately.

How to Build and Run

Build the image:

docker build -t product-catalog-service .

Run the container:

docker run -p 8088:8088 product-catalog-service