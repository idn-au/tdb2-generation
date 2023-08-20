FROM openjdk:22-slim-bullseye as base

COPY --from=ghcr.io/zazuko/spatial-indexer:latest /app/spatialindexer.jar /spatialindexer.jar

# Set environment variables
ENV JENA_VERSION=4.9.0

# Update system packages, install required tools, set up AWS CLI, and fetch & unpack Jena and Jena Fuseki
RUN apt-get update -y && \
    apt-get install -y sudo unzip curl jq && \
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && rm awscliv2.zip && \
    sudo ./aws/install && \
    curl "https://dlcdn.apache.org/jena/binaries/apache-jena-$JENA_VERSION.tar.gz" -o "/jena.tar.gz" && \
    tar -xzf jena.tar.gz && rm jena.tar.gz && \
    curl "https://dlcdn.apache.org/jena/binaries/apache-jena-fuseki-$JENA_VERSION.tar.gz" -o "/fuseki.tar.gz" && \
    tar -xzf fuseki.tar.gz apache-jena-fuseki-$JENA_VERSION/fuseki-server.jar && \
    mv apache-jena-fuseki-$JENA_VERSION/fuseki-server.jar /fuseki-server.jar && \
    rm fuseki.tar.gz && \
    rmdir apache-jena-fuseki-$JENA_VERSION

# Copy scripts and SPARQL queries
COPY ./entrypoint.sh /entrypoint.sh
COPY *.sparql /

# Set the working directory
WORKDIR /apache-jena-$JENA_VERSION/bin/

# Set the entrypoint
ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]

# Default CMD
CMD []
