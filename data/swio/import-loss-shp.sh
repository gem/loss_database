if [ $# -lt 1 ] 
then
	echo "Usage $0 <shapefile>"
	exit 1
fi

filename=$1
table_name=$(basename $filename .shp)

echo "shp2pgsql -c -W UTF-8 -s 4326 $filename temp.$table_name  > $table_name.sql"
shp2pgsql -c -W UTF-8 -s 4326 "$filename" temp.$table_name  > $table_name.sql
