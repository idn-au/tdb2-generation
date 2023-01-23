files="/rdf/fc-and-dataset-power-substations.ttl /rdf/fc-and-dataset.ttl /rdf/power_substations.ttl /rdf/power_substations_context.ttl /rdf/power_stations.nq"
nq_files=""
other_files=""
for file in $files
do
  if [[ $file == *.nq ]]
  then
    nq_files="$nq_files $file"
  else
    other_files="$other_files $file"
  fi
done
echo $nq_files
echo $other_files