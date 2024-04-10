(Note: this was previously a fork of [Kurrawong/tdb2-generation](https://github.com/Kurrawong/tdb2-generation))

This docker image is used to generate TDB2 datasets used by Fuseki.
It includes:

1. Validation of RDF files using Apache Jena RIOT
   Files that fail validation are renamed with the suffix `.error` - this prevents tdbloader attempting to load them.
2. Creation of TDB2 datasets using `tdb2.tdbloader` or `tdb2.xloader` (for large datasets)
3. Creation of a Spatial Index for use with Apache Jena GeoSPARQL
3. Creation of a Text Index for use with Lucene Text Index
4. Addition of Feature counts (via. a tdb2.update SPARQL update) - this is specific to OGC conformant datasets which contain geo:Features, and will be made optional in future versions (though the command will run harmlessly otherwise!).

To pull this image:

```
docker pull ghcr.io/idn-au/tdb2-generation:latest
```

To run this image locally, using data from OpenStack Swift:
```
docker run \
   -v <host_db_dir>:/fuseki \
   -e OS_AUTH_URL=<keystone_auth_url> \
   -e OS_PROJECT_ID=<openstack_project_id> \
   -e OS_PROJECT_NAME=<openstack_project_name> \
   -e OS_USER_DOMAIN_NAME=<openstack_project_domain_name> \
   -e OS_PROJECT_DOMAIN_ID=<openstack_project_domain_id> \
   -e OS_USERNAME=<username> \
   -e OS_PASSWORD=<password> \
   -e OS_REGION_NAME=<region_name> \
   -e OS_INTERFACE=<interface> \
   -e OS_IDENTITY_API_VERSION=<keystone_version> \
   -e SWIFT_CONTAINER=<swift_container_name> \
   -e DATASET=<dataset_name> \
   ghcr.io/idn-au/tdb2-generation:latest
```
or use an `.env` file or OpenStack `clouds.yaml` file or some other way to set OpenStack Swift CLI config variables.

To run this image locally using local data:
```
docker run \
   -v mydbvolume:/fuseki \
   --mount type=bind,source=<host_data_dir>,target=/rdf \
   -e DATASET=<dataset_name> \
   ghcr.io/idn-au/tdb2-generation:latest
```

To process a large (say, >30GB) dataset, use tdb2.xloader. For example:

```
docker run \
   -v <host_db_dir>:/fuseki \
   -e OS_AUTH_URL=<keystone_auth_url> \
   -e OS_PROJECT_ID=<openstack_project_id> \
   -e OS_PROJECT_NAME=<openstack_project_name> \
   -e OS_USER_DOMAIN_NAME=<openstack_project_domain_name> \
   -e OS_PROJECT_DOMAIN_ID=<openstack_project_domain_id> \
   -e OS_USERNAME=<username> \
   -e OS_PASSWORD=<password> \
   -e OS_REGION_NAME=<region_name> \
   -e OS_INTERFACE=<interface> \
   -e OS_IDENTITY_API_VERSION=<keystone_version> \
   -e SWIFT_CONTAINER=<swift_container_name> \
   -e DATASET=<dataset_name> \
   -e USE_XLOADER=true \
   -e THREADS=<N_cores-1> \
   ghcr.io/idn-au/tdb2-generation:latest
```
