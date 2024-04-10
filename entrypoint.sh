#!/bin/bash

echo Starting Processing
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

if ! [ -z ${SWIFT_CONTAINER+x} ]; then
    echo "Downloading files from Swift..."
    swift download --output-dir /rdf $SWIFT_CONTAINER
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

    if ! output=$(riot --validate --quiet $file 2>&1); then
      # This means an error occurred since the exit code is non-zero.
      echo "Error in file $file"
      echo "$output"  # display the error
      mv -- $file ${file}.error
    else
      # No error occurred. Handle warnings or regular messages as needed.
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
  if [[ "$nq_files" != "" ]]; then
    tdb2.xloader --threads $THREADS --loc /fuseki/databases/${DATASET} $nq_files
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
    tdb2.tdbloader --loader=$TDB2_MODE --loc /fuseki/databases/${DATASET} --verbose $nq_files
  fi
  if [ "$other_files" != "" ]; then
    tdb2.tdbloader --loader=$TDB2_MODE --loc /fuseki/databases/${DATASET} --graph https://default $other_files
  fi
fi

chmod 755 -R /fuseki/databases/${DATASET}
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
    --dataset /fuseki/databases/${DATASET} \
    --index /fuseki/databases/${DATASET}/spatial.index
fi
# \
# Create a Lucene text index \
# \
java -cp /fuseki-server.jar jena.textindexer --desc=/fuseki/config.ttl
