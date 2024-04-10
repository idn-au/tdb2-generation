FROM openjdk:22-slim-bullseye as base

# Set environment variables
ENV JENA_VERSION=4.9.0

# Update system packages, install required tools, set up Swift CLI
RUN apt update && \
    apt -y install unzip curl jq python3-pip && \
    pip3 install python-keystoneclient python-swiftclient

# Add a user `fuseki` with no password, create a home directory for the user
# -D option for no password, -h for home directory
RUN adduser --disabled-password --gecos "" --home /home/fuseki fuseki

# Fetch & unpack Jena and Jena Fuseki
RUN curl "https://archive.apache.org/dist/jena/binaries/apache-jena-$JENA_VERSION.tar.gz" -o "/jena.tar.gz" && \
    tar -xzf /jena.tar.gz && rm /jena.tar.gz && \
    curl "https://archive.apache.org/dist/jena/binaries/apache-jena-fuseki-$JENA_VERSION.tar.gz" -o "/fuseki.tar.gz" && \
    tar -xzf /fuseki.tar.gz apache-jena-fuseki-$JENA_VERSION/fuseki-server.jar && \
    mv apache-jena-fuseki-$JENA_VERSION/fuseki-server.jar /fuseki-server.jar && \
    rm /fuseki.tar.gz && \
    rm -r apache-jena-fuseki-$JENA_VERSION

# Copy the spatialindexer.jar file
COPY --from=ghcr.io/zazuko/spatial-indexer:latest /app/spatialindexer.jar /spatialindexer.jar

# Copy scripts, ensure they're owned by fuseki
COPY ./entrypoint.sh /entrypoint.sh
COPY ./sparql/*.sparql /
RUN chown fuseki /entrypoint.sh && chmod +x /entrypoint.sh

# Set the working directory to the home directory of fuseki
WORKDIR /home/fuseki

# Add binaries to PATH
ENV PATH="/apache-jena-${JENA_VERSION}/bin:${PATH}"

# Switch to user `fuseki` for subsequent commands
USER fuseki

# Set the entrypoint
ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]

# Default CMD
CMD []
