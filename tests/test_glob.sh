extensions="rdf ttl owl nt nquads nq"
PATTERNS=""
for e in $extensions ; do
  PATTERNS="$PATTERNS *.$e *.$e.gz"
done
if [ $# -eq 0 ] ; then
  patterns="$PATTERNS"
else
  patterns="$@"
fi
files=""
for f in $patterns; do
  if [ -f "$f" ] ; then
    files="$files $f"
  fi
done
echo $files
