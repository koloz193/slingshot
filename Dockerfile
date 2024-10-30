# Step 1: Use the official Rust image as the build environment
FROM ubuntu:latest

# Step 2: Create a new directory for the app
WORKDIR /usr/src/slingshot

# Step 3: Copy the local files to the container
COPY . .

USER root

RUN apt-get update && apt-get install -y \
    curl \
    git

SHELL ["/bin/bash", "-c"]

RUN curl -L https://foundry.paradigm.xyz | bash
RUN source ~/.bashrc
ENV PATH="~/.foundry/bin:${PATH}"
RUN foundryup

RUN curl -L https://raw.githubusercontent.com/matter-labs/foundry-zksync/main/install-foundry-zksync | bash
RUN foundryup-zksync

RUN source ~/.bashrc
ENV PATH="~/.foundry/bin:${PATH}"

RUN forge install --no-git
RUN forge build

ARG PRIV_KEY
ENV PRIV_KEY=${PRIV_KEY}

ARG CHAIN_1_RPC
ENV CHAIN_1_RPC=${CHAIN_1_RPC}

ARG CHAIN_2_RPC
ENV CHAIN_2_RPC=${CHAIN_2_RPC}

RUN echo "forge script script/Deploy.s.sol:Deploy --rpc-url ${CHAIN_1_RPC} --private-key ${PRIV_KEY} --zksync  --skip-simulation  --enable-eravm-extensions --broadcast && forge script script/Deploy.s.sol:Deploy --rpc-url ${CHAIN_2_RPC} --private-key ${PRIV_KEY} --zksync  --skip-simulation  --enable-eravm-extensions --broadcast" > ./entrypoint.sh 
RUN chmod +x ./entrypoint.sh

CMD ["/bin/bash", "-c", "./entrypoint.sh"]