# Use the official Rust image as the base image
FROM rust:latest AS builder

# Install MUSL tools
RUN apt-get update && apt-get install -y musl-tools && \
  rustup target add x86_64-unknown-linux-musl

# Set the working directory
WORKDIR /usr/src/app

# Copy the source code into the container
COPY . .

# Build the Rust application with MUSL target
RUN cargo build --release --target=x86_64-unknown-linux-musl

# Create a minimal runtime image
FROM alpine:latest

# Install necessary libraries
RUN apk --no-cache add ca-certificates

# Set the working directory
WORKDIR /app

# Copy the statically linked binary from the builder stage
COPY --from=builder /usr/src/app/target/x86_64-unknown-linux-musl/release/wasm /app/

# Set the binary as the entrypoint
ENTRYPOINT ["./wasm"]
