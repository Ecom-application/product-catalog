# Stage 1: Build the application
FROM golang:1.22-alpine AS builder

# Install build dependencies
RUN apk add --no-cache git ca-certificates

WORKDIR /usr/src/app

# Copy dependency files first to leverage Docker cache
COPY go.mod go.sum ./
RUN go mod download

# Copy the rest of the source code
COPY . .

# Build the application with optimizations for containers:
# -ldflags="-s -w" reduces binary size by removing debug info
# CGO_ENABLED=0 ensures a statically linked binary
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o product-catalog .

# Stage 2: Create the final lightweight image
FROM alpine:3.19

# Set up a non-root user for security
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

WORKDIR /app

# Copy the binary from the builder stage
COPY --from=builder /usr/src/app/product-catalog .

# Copy the required data files (products.json)
# The application expects them in a ./products directory
COPY --from=builder /usr/src/app/products ./products

# The application requires this environment variable
ENV PRODUCT_CATALOG_PORT=8088
EXPOSE 8088

# Run the binary
ENTRYPOINT ["./product-catalog"]
