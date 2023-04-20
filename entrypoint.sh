echo Starting Processing
mkdir /rdf
java -XX:+PrintFlagsFinal -version | grep -Ei "maxheapsize|maxram"
# \
# Use a dataset name if specified, else use "db"
# \
if [ -n "${DATASET}" ]; then
  DATASET=${DATASET}
  echo using DATASET specified via environment variable: ${DATASET}
else
  DATASET=db
fi
# \
# Create a list of file extensions \
# \
extensions="rdf ttl owl nt nquads nq"
PATTERNS=""
for e in ${extensions}; do
  PATTERNS="${PATTERNS} *.${e} *.${e}.gz"
done
if [ $# -eq 0 ]; then
  patterns="${PATTERNS}"
else
  patterns="$@"
fi


if ! [ -z ${S3_BUCKET+x} ]; then
  # \
# Download the files from S3 if a bucket and directory is given (requires permission) \
# \
  s3_include=""
  for pattern in ${patterns}; do
    var=" --include "

  if [ -z "${S3_DIRECTORY}" ]; then
  s3_include=$s3_include$var$pattern
    else
      for dir in ${S3_DIRECTORY}; do
        s3_include=$s3_include$var$dir/$pattern
      done
    fi
  done

  echo 's3 include expression is:'
  echo $s3_include

  aws s3 sync s3://${S3_BUCKET}/ /rdf --exclude "*" $s3_include

  echo 'Downloaded files listing:'
  for dir in ${S3_DIRECTORY}; do
    echo files in $dir:
    ls -lah /rdf/$dir
  done
fi

# \
# create a list of the files\
# \
files=""
for pattern in $patterns; do
  files="${files} $(find /rdf -type f -name "${pattern}")"
done
echo "The following RDF files have been found and will be validated:"
echo ${files} | tr " " "\n"
echo "##############################"
# \
# Validate the files \
# \
if [ -z ${SKIP_VALIDATION+x} ]; then
  for file in $files; do
    echo Validating $file
    if ! ./riot --validate --quiet $file; then
      echo Above error in file "$file" && mv -- $file ${file}.error
    else
      echo File $file is valid rdf
    fi
  done
else
  echo "Skipping validation"
fi
# \
# Recreate files list (to exclude errored files) \
# \
files=""
for pattern in $patterns; do
  files="${files} $(find /rdf -type f -name "${pattern}")"
done
echo "##############################"
echo "The following RDF files will be processed:"
echo ${files} | tr " " "\n"
echo "##############################"
# \
# Create a TDB2 dataset \
# \
nq_files=""
other_files=""
for file in $files; do
  if [[ ${file} == *.nq ]]; then
    nq_files="$nq_files $file"
  else
    other_files="$other_files $file"
  fi
done
if [ -n "${USE_XLOADER}" ]; then
  if [ "$nq_files" != "" ]; then
    ./tdb2.xloader --threads $THREADS --loc /newdb/${DATASET} $nq_files
    else
      echo Error: No files with extension .nq found - xloader can only be used with nquads files
  fi
else
  if [ -n "${TDB2_MODE}" ]; then
    TDB2_MODE=${TDB2_MODE}
    echo using TDB2_MODE specified via environment variable: ${TDB2_MODE}
  else
    TDB2_MODE=phased
    echo using default TDB2_MODE: ${TDB2_MODE}
  fi
  if [ "$nq_files" != "" ]; then
    ./tdb2.tdbloader --loader=$TDB2_MODE --loc /newdb/${DATASET} --verbose $nq_files
  fi
  if [ "$other_files" != "" ]; then
    ./tdb2.tdbloader --loader=$TDB2_MODE --loc /newdb/${DATASET} --graph https://default $other_files
  fi
fi

chmod 755 -R /newdb/${DATASET}
# \
# Create a spatial index \
# \
if [ "$NO_SPATIAL" = true ]; then
  echo "##############################"
  echo Skipping spatial index creation - NO_SPATIAL environment variable is set to true
else
  echo "##############################"
  echo Generating spatial index
  java -jar /spatialindexer.jar \
    --dataset /newdb/${DATASET} \
    --index /newdb/${DATASET}/spatial.index
fi
# \
# Create a Lucene text index \
# \
#rm /newdb/${DATASET}/tdb.lock
#rm /newdb/${DATASET}/write.lock
#rm /newdb/${DATASET}/Data-0001/tdb.lock
java -cp /fuseki-server.jar jena.textindexer --desc=/config.ttl
# \
# add a count to the dataset\
# \
./tdb2.tdbupdate --loc /newdb/${DATASET} --update /construct_feature_counts.sparql
./tdb2.tdbupdate --loc /newdb/${DATASET} --update /construct_feature_counts_triples.sparql
echo "##############################"
echo "Feature Collection Counts - added to "prez:metadata" named graph "
./tdb2.tdbquery --loc /newdb/${DATASET} --query /select_feature_counts.sparql
# \
# Cleanup locks \
# \
rm /newdb/${DATASET}/tdb.lock
rm /newdb/${DATASET}/write.lock
rm /newdb/${DATASET}/Data-0001/tdb.lock
