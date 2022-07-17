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
COPY "./apache-jena-4.5.0.tar.gz" "/apache-jena-4.5.0.tar.gz"
COPY ./construct_feature_counts.sparql /construct_feature_counts.sparql
COPY ./select_feature_counts.sparql /select_feature_counts.sparql
CMD  ["bash", "-c", "echo Processing ${TDB2_DATASET};\
        apt-get install -y jq;\
        cd / && tar -xzf /apache-jena-4.5.0.tar.gz;\
        java -XX:+PrintFlagsFinal -version | grep -Ei \"maxheapsize|maxram\";\
        # \
        # Create a list of file extensions \
        # \
        extensions=\"rdf ttl owl nt nquads nq\";\
        PATTERNS=\"\";\
        for e in ${extensions} ;\
        do\
          PATTERNS=\"${PATTERNS} *.${e} *.${e}.gz\";\
        done;\
        if [ $# -eq 0 ] ;\
         then patterns=\"${PATTERNS}\";\
        else\
          patterns=\"$@\";\
        fi;\
        # \
        # Download the files from S3 if a bucket and directory is given (requires permission) \
        # \
        if ! [ -z ${S3_DIRECTORY+x} ];\
            then\
            s3_include=\"\";\
            for dir in ${S3_DIRECTORY};\
            do\
                var=\" --include \";\
                s3_include=$s3_include$var$dir/*.nt;\
            done;\
            echo 's3 include is';\
            echo $s3_include;\
            aws s3 sync s3://${S3_BUCKET}/ /rdf --exclude \"*\" $s3_include;\
            echo 'Downloaded files listing:';\
            for dir in ${S3_DIRECTORY};\
            do\
                ls -lah /rdf/$dir;\
            done;\
        fi;\
        # \
        # create a list of the files\
        # \
        files=\"\";\
        for pattern in $patterns;\
        do\
          files=\"${files} $(find /rdf -type f -name \"${pattern}\")\";\
        done;\
        echo \"The following RDF files have been found and will be validated:\";\
        echo ${files} | tr \" \" \"\n\";\
        echo \"##############################\";\
        # \
        # Validate the files \
        # \
        if [ -z ${SKIP_VALIDATION+x} ];\
            then for file in $files;\
            do\
                    echo Validating $file;\
                    if ! riot --validate --quiet $file;\
                            then echo Above error in file \"$file\" && mv -- $file ${file}.error;\
                            else echo File       $file is valid rdf;\
                    fi;\
            done;\
        fi;\
        # \
        # Recreate files list (to exclude errored files) \
        # \
        files=\"\";\
        for pattern in $patterns;\
        do\
          files=\"${files} $(find /rdf -type f -name \"${pattern}\")\";\
        done;\
        echo \"##############################\";\
        echo \"The following RDF files do NOT have issues and will be processed:\";\
        echo ${files} | tr \" \" \"\n\";\
        echo \"##############################\";\
        # \
        # Create a TDB2 dataset \
        # \
        nq_files=\"\";\
        other_files=\"\";\
        for file in $files;\
        do\
          if [[ ${file} == *.nq ]];\
          then nq_files=\"$nq_files $file\";\
          else other_files=\"$other_files $file\";\
          fi;\
        done;\
        if [ -z ${TDB2_MODE+x} ];\
            then TDB2_MODE=phased;\
            else TDB2_MODE=${TDB2_MODE};\
        fi;\
#        tdb2.tdbloader --loader=$TDB2_MODE --loc /newdb/db --verbose $nq_files ;\
        /apache-jena-4.5.0/bin/tdb2.xloader --threads $THREADS --loc /newdb/db $other_files ;\
        tdb2.tdbloader --loc /newdb/db --graph https://default $other_files ;\
        chmod 755 -R /newdb/db;\
        # \
        # Create a spatial index \
        # \
            java -jar /spatialindexer.jar \
                   --dataset /newdb/db \
                   --index /newdb/db/spatial.index;\
        # \
        # add a count to the dataset\
        # \
        tdb2.tdbupdate --loc /newdb/db --update /construct_feature_counts.sparql;\
        echo \"##############################\";\
        echo \"Feature Collection Counts - added to \"prez:metadata\" named graph \";\
        tdb2.tdbquery --loc /newdb/db --query /select_feature_counts.sparql;\
        # \
        # Cleanup locks \
        # \
            rm /newdb/db/tdb.lock;\
            rm /newdb/db/Data-0001/tdb.lock;\
        "]
