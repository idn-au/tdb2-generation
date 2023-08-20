This docker image is used to generate TDB2 datasets used by Fuseki.
It includes:

1. Validation of RDF files using Apache Jena RIOT
   Files that fail validation are renamed with the suffix `.error` - this prevents tdbloader attempting to load them.
2. Creation of TDB2 datasets using `tdb2.tdbloader` or `tdb2.xloader` (for large datasets)
3. Creation of a Spatial Index for use with Apache Jena GeoSPARQL
4. Addition of Feature counts (via. a tdb2.update SPARQL update) - this is specific to OGC conformant datasets which contain geo:Features, and will be made optional in future versions (though the command will run harmlessly otherwise!).

An additional set of instructions is also provided for running this Dockerfile on an EC2 instance - note this has only been necessary for very large datasets.

Example command to build this image:
`docker build -t tdb-generation .`
Example command to run this image locally, using data from S3:
```
docker run \
   -v <host_db_dir>:/newdb \
   -e AWS_ACCESS_KEY_ID=<YOUR ACCESS KEY HERE> \
   -e AWS_SECRET_ACCESS_KEY=<YOUR SECRET HERE> \
   -e S3_BUCKET=<YOUR S3 BUCKET HERE> \
   -e S3_DIRECTORY=<YOUR S3 DIRECTORY HERE> \
   -e DATASET=mydataset \
   tdb2-generation:<image_version>
```

Example command to run this image locally, using local data:
```
docker run \
   -v mydbvolume:/newdb \
   --mount type=bind,source=<host_data_dir>,target=/rdf \
   -e DATASET=mydataset \
   tdb-generation:<image_version>
```

To process a large (say, >30GB) dataset, use tdb2.xloader. For example:

```
docker run \
   -v <host_db_dir>:/newdb \
   -e AWS_ACCESS_KEY_ID=<YOUR ACCESS KEY HERE> \
   -e AWS_SECRET_ACCESS_KEY=<YOUR SECRET HERE> \
   -e S3_BUCKET=<YOUR S3 BUCKET HERE> \
   -e S3_DIRECTORY=<YOUR S3 DIRECTORY HERE> \
   -e DATASET=mydataset \
   -e USE_XLOADER=true \
   -e THREADS=<N_cores-1> \
   tdb-generation:<image_version>
```

_NB when run using the ECS task definitions supplied for both the PID and DA projects_ the AWS credentials do not need to be supplied - the relevant policy has been specified in terraform to give ECS access to read/write from the relevant S3 buckets. The mount will utilise an EFS volume specified in Terraform. The command that is run in ECS will be along the lines of:

```
docker run \
   -v <efs_volume>:/newdb \
   -e S3_BUCKET=<YOUR S3 BUCKET HERE> \
   -e S3_DIRECTORY=<YOUR S3 DIRECTORY HERE> \
   -e DATASET=mydataset \
   tdb-generation:<image_version>
```