# Use a base image
FROM ubuntu:18.04

# Set the working directory
WORKDIR /root

# Mount the current folder as /root/aid-tracker-interactive
COPY . /root/aid-tracker-interactive

RUN echo 'tzdata tzdata/Areas select Europe' | debconf-set-selections 
RUN echo 'tzdata tzdata/Zones/Europe select London' | debconf-set-selections

# Install r-base-core using apt
RUN apt-get update && \
    DEBIAN_FRONTEND="noninteractive" apt-get install -y r-base-core

