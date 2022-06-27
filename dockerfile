FROM stain/jena:latest
COPY --from=ghcr.io/zazuko/spatial-indexer:latest /app/spatialindexer.jar /spatialindexer.jar
RUN apt-get update -y
RUN apt-get install -y unzip
RUN apt-get install -y sudo
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
RUN unzip awscliv2.zip
RUN sudo ./aws/install
# TODO setup additional file extension matching see exampe in https://github.com/stain/jena-docker/blob/master/jena-fuseki/load.sh
CMD  ["sh", "-c", "echo Processing ${TDB2_DATASET};\
        # \
        # Download the files from S3 - requires permission \
        # \
            aws s3 sync s3://${S3_BUCKET}/ ./ --exclude \"*\" --include \"${S3_DIRECTORY}*\";\
            echo 'Downloaded files listing:'; ls -lah ${S3_DIRECTORY};\
        # \
        # Validate the files \
        # \
            for file in ${S3_DIRECTORY}/*.nq;\
            do\
                    echo Validating $file;\
                    if ! riot --validate --quiet $file;\
                            then echo Above error in file \"$file\" && mv -- $file ${file%.nq}.error;\
                            else echo File       $file is valid rdf;\
                    fi;\
            done;\
        # \
        # Create a TDB2 dataset \
        # \
            tdb2.tdbloader --loc /fuseki/databases/db ${S3_DIRECTORY}/*.nq;\
            chmod 755 -R /fuseki/databases/db;\
            ###################### \
            # Create a TDB2 dataset \
        # \
        # Create a spatial index \
        # \
            java -jar /spatialindexer.jar \
                   --dataset /fuseki/databases/db \
                   --index /fuseki/databases/db/spatial.index;\
        # \
        # Cleanup locks \
        # \
            rm /fuseki/databases/db/tdb.lock;\
            rm /fuseki/databases/db/Data-0001/tdb.lock;\
        "]