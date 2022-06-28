FROM stain/jena:latest
COPY --from=ghcr.io/zazuko/spatial-indexer:latest /app/spatialindexer.jar /spatialindexer.jar
RUN apt-get update -y  \
    && apt-get install -y unzip \
    && apt-get install -y sudo \
    && curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && sudo ./aws/install
# TODO setup additional file extension matching see exampe in https://github.com/stain/jena-docker/blob/master/jena-fuseki/load.sh
# or use e.g. `export FILES={*.ttl,*.ttl.gz,*.nt,*}
CMD  ["sh", "-c", "echo Processing ${TDB2_DATASET};\
        s3_include=\"\";\
        for dir in ${S3_DIRECTORY};\
        do\
            var=\" --include \";\
            s3_include=$s3_include$var$dir/*.nq;\
        done;\
        # \
        # Download the files from S3 - requires permission \
        # \
            aws s3 sync s3://${S3_BUCKET}/ ./data --exclude \"*\" $s3_include;\
            echo 'Downloaded files listing:';\
            for dir in ${S3_DIRECTORY};\
            do\
                ls -lah ./data/$dir;\
            done;\
        # \
        # Validate the files \
        # \
            for file in ./data/**/*.nq;\
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
            tdb2.tdbloader --loc /fuseki/databases/db ./data/**/*.nq;\
            chmod 755 -R /fuseki/databases/db;\
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
