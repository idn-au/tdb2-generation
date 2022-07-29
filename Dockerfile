FROM stain/jena:latest
COPY --from=ghcr.io/zazuko/spatial-indexer:latest /app/spatialindexer.jar /spatialindexer.jar
RUN apt-get update -y  \
    && apt-get install -y unzip \
    && apt-get install -y sudo \
    && curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && sudo ./aws/install
COPY "./apache-jena-4.5.0.tar.gz" "/apache-jena-4.5.0.tar.gz"
COPY ./entrypoint.sh /entrypoint.sh
COPY ./construct_feature_counts.sparql /construct_feature_counts.sparql
COPY ./select_feature_counts.sparql /select_feature_counts.sparql
ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]