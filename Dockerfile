# Use a base image with Linux (e.g., Ubuntu) that supports apt
FROM ubuntu:latest

# Set the working directory
WORKDIR /root

# Mount the current folder as /root/aid-tracker-interactive
COPY . /root/aid-tracker-interactive

# Mount the folder /root/ddw-analyst-ui as /root/ddw-analyst-ui
COPY /root/ddw-analyst-ui /root/ddw-analyst-ui

# Install r-base-core using apt
RUN apt-get update && \
    apt-get install -y r-base-core && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

