# Step 1: Use the official Rust image as the build environment
FROM rust:latest AS builder

# Step 2: Create a new directory for the app
WORKDIR /usr/src/slingshot/cli

# Step 3: Copy the local files to the container
COPY ./cli/ .

# Step 4: Build the Rust program
RUN cargo build --release

# Use a newer base image for the runtime
FROM ubuntu:latest

ARG PRIV_KEY
ENV PRIV_KEY=${PRIV_KEY}

ARG INTEROP_ADDR
ENV INTEROP_ADDR=${INTEROP_ADDR}

ARG CHAIN_1_RPC
ENV CHAIN_1_RPC=${CHAIN_1_RPC}

ARG CHAIN_2_RPC
ENV CHAIN_2_RPC=${CHAIN_2_RPC}

# Set up dependencies
RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*

# Step 7: Set up a user for running the server
ENV USER=slingshot
RUN useradd -m $USER

# Step 8: Copy the compiled binary from the build container
COPY --from=builder /usr/src/slingshot/cli/target/release/cli /usr/local/bin/slingshot

# Step 9: Verify and set execute permissions
RUN chmod +x /usr/local/bin/slingshot && \
    chown -R $USER:$USER /usr/local/bin/slingshot

# Step 10: Switch to the new user
USER root

# Step 12: Explicitly run the server binary with its full path
CMD ["sh", "-c", "/usr/local/bin/slingshot -r ${CHAIN_1_RPC} ${INTEROP_ADDR} -r ${CHAIN_2_RPC} ${INTEROP_ADDR} --private-key ${PRIV_KEY}"]
