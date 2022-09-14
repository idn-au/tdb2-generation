FROM openjdk:11-jre-slim-bullseye
COPY --from=ghcr.io/zazuko/spatial-indexer:latest /app/spatialindexer.jar /spatialindexer.jar
ARG JENA_VERSION=4.6.1
RUN apt-get update -y \
    && apt-get install sudo unzip curl -y \
    && curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && curl "https://dlcdn.apache.org/jena/binaries/apache-jena-$JENA_VERSION.tar.gz" -o "/fuseki.tar.gz" \
    && unzip awscliv2.zip && rm awscliv2.zip \
    && sudo ./aws/install \
    && apt-get install -y jq \
    && tar -xzf fuseki.tar.gz && rm fuseki.tar.gz
COPY ./entrypoint.sh /entrypoint.sh
COPY *.sparql /
WORKDIR /apache-jena-$JENA_VERSION/bin/
ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]