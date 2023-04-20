FROM openjdk:11-jre-slim-bullseye
COPY --from=ghcr.io/zazuko/spatial-indexer:latest /app/spatialindexer.jar /spatialindexer.jar
ARG JENA_VERSION=4.7.0
ARG CONFIG_FILE_LOCATION
RUN apt-get update -y \
    && apt-get install sudo unzip curl -y \
    && apt-get install -y jq \
    && curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip && rm awscliv2.zip \
    && sudo ./aws/install \
    && curl "https://dlcdn.apache.org/jena/binaries/apache-jena-$JENA_VERSION.tar.gz" -o "/jena.tar.gz" \
    && tar -xzf jena.tar.gz && rm jena.tar.gz \
    && curl "https://dlcdn.apache.org/jena/binaries/apache-jena-fuseki-$JENA_VERSION.tar.gz" -o "/fuseki.tar.gz" \
    && tar -xzf fuseki.tar.gz apache-jena-fuseki-4.7.0/fuseki-server.jar \
    && mv apache-jena-fuseki-4.7.0/fuseki-server.jar /fuseki-server.jar \
    && rm fuseki.tar.gz \
    && rmdir apache-jena-fuseki-4.7.0
COPY ./entrypoint.sh /entrypoint.sh
COPY *.sparql /
COPY ${CONFIG_FILE_LOCATION} /config.ttl
WORKDIR /apache-jena-$JENA_VERSION/bin/
ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]
CMD []
